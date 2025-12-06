#!/bin/bash

set -e  # Exit on any error

# --- START NVM ---
# Load the NVM environment specifically for non-interactive shells
export NVM_DIR="/home/deployer/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# --- END NVM ---

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

LOCK_FILE="/tmp/deploy.lock"

# Check if deployment is already running
if [ -f "$LOCK_FILE" ]; then
    echo -e "${RED}❌ Deployment already in progress${NC}"
    echo -e "${YELLOW}Lock file: $LOCK_FILE${NC}"
    echo -e "${YELLOW}If this is an error, remove: rm $LOCK_FILE${NC}"
    exit 1
fi

# Create lock file
touch "$LOCK_FILE"

# Ensure lock is removed on exit (success or failure)
trap "rm -f $LOCK_FILE" EXIT

# Check for force flag
FORCE_REBUILD=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    FORCE_REBUILD=true
    echo -e "${YELLOW}🔨 Force rebuild requested${NC}"
fi

echo -e "${GREEN}🚀 Starting deployment...${NC}"

# Navigate to project directory
cd /var/www/sontra/sontra-website || exit 1

# Store current commit for rollback
PREVIOUS_COMMIT=$(git rev-parse HEAD)
echo -e "${YELLOW}📝 Current commit: ${PREVIOUS_COMMIT}${NC}"

# Check current container health BEFORE pulling changes
echo -e "${YELLOW}🏥 Checking current container health...${NC}"
CONTAINER_HEALTHY=false

if docker compose ps 2>/dev/null | grep -q "sontra-website.*Up"; then
    if curl -f -s -o /dev/null http://localhost:4321 2>/dev/null; then
        CONTAINER_HEALTHY=true
        echo -e "${GREEN}✅ Container is currently healthy${NC}"
    else
        echo -e "${RED}⚠️  Container is running but not responding${NC}"
    fi
else
    echo -e "${RED}⚠️  Container is not running${NC}"
fi

# Pull latest code
echo -e "${YELLOW}⬇️  Pulling latest changes from GitHub...${NC}"
git fetch origin main
git reset --hard origin/main

# Show what changed
NEW_COMMIT=$(git rev-parse HEAD)
echo -e "${GREEN}✅ Updated to commit: ${NEW_COMMIT}${NC}"

# Decision logic: Skip deployment ONLY if commits match AND container is healthy OR FORCE_REBUILD flag missing
if [ "$PREVIOUS_COMMIT" = "$NEW_COMMIT" ] && [ "$CONTAINER_HEALTHY" = true ] && [ "$FORCE_REBUILD" = false ]; then
    echo -e "${GREEN}ℹ️  No changes detected and container is healthy. Skipping rebuild.${NC}"
    echo -e "${GREEN}🌐 Site is already live at https://sontra.dev${NC}"
    exit 0
elif [ "$PREVIOUS_COMMIT" = "$NEW_COMMIT" ]; then
    echo -e "${YELLOW}⚠️  No code changes, but container is unhealthy. Rebuilding...${NC}"
else
    echo -e "${BLUE}📦 Code changes detected. Rebuilding...${NC}"
    git log --oneline "${PREVIOUS_COMMIT}..${NEW_COMMIT}" | head -5
fi

# Navigate to parent directory for docker-compose
cd /var/www/sontra || exit 1

# Build new Docker image
echo -e "${YELLOW}🔨 Building Docker image...${NC}"
docker compose build --no-cache astro-web

# Stop old container
echo -e "${YELLOW}🛑 Stopping old container...${NC}"
docker compose down

# Start new container
echo -e "${YELLOW}🚀 Starting new container...${NC}"
docker compose up -d

# Wait for container to be ready with proper health check
echo -e "${YELLOW}⏳ Waiting for container to be ready...${NC}"

MAX_WAIT=120  # Maximum wait time in seconds (2 minutes)
WAIT_INTERVAL=3  # Check every 3 seconds
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
    # Check if container is running
    if docker compose ps | grep -q "sontra-website.*Up"; then
        # Container is up, now check if it's actually responding
        if curl -f -s -o /dev/null http://localhost:4321; then
            echo -e "${GREEN}✅ Container is ready and responding!${NC}"
            echo -e "${BLUE}⏱️  Took ${ELAPSED} seconds to start${NC}"
            break
        else
            echo -e "${BLUE}⏳ Container running but not responding yet... (${ELAPSED}s)${NC}"
        fi
    else
        echo -e "${BLUE}⏳ Container starting... (${ELAPSED}s)${NC}"
    fi
    
    sleep $WAIT_INTERVAL
    ELAPSED=$((ELAPSED + WAIT_INTERVAL))
done

# Final health check
if docker compose ps | grep -q "Up" && curl -f -s -o /dev/null http://localhost:4321; then
    echo -e "${GREEN}✅ Deployment successful!${NC}"
    echo -e "${GREEN}🌐 Site is live at https://sontra.dev${NC}"
    
    # Show recent commits
    echo -e "${YELLOW}📝 Recent commits:${NC}"
    cd /var/www/sontra/sontra-website
    git log --oneline -3
    
    # Show logs
    echo -e "${YELLOW}📋 Recent container logs:${NC}"
    cd /var/www/sontra
    docker compose logs --tail=20 astro-web
    
    exit 0
else
    echo -e "${RED}❌ Deployment failed! Container is not responding after ${MAX_WAIT} seconds.${NC}"
    echo -e "${YELLOW}📋 Container logs:${NC}"
    docker compose logs --tail=50 astro-web
    
    echo -e "${YELLOW}🔄 Rolling back to previous commit...${NC}"
    
    cd /var/www/sontra/sontra-website
    git reset --hard "$PREVIOUS_COMMIT"
    cd /var/www/sontra
    docker compose build astro-web
    docker compose up -d
    
    # Wait for rollback container to start
    echo -e "${YELLOW}⏳ Waiting for rollback to complete...${NC}"
    sleep 10
    
    if docker compose ps | grep -q "Up" && curl -f -s -o /dev/null http://localhost:4321; then
        echo -e "${GREEN}✅ Successfully rolled back to ${PREVIOUS_COMMIT}${NC}"
    else
        echo -e "${RED}❌ Rollback failed! Manual intervention required.${NC}"
        echo -e "${RED}📞 Contact: erick@contactsontra.dev${NC}"
    fi
    
    exit 1
fi