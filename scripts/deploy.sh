#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- START NVM ---
# Load the NVM environment specifically for non-interactive shells
export NVM_DIR="/home/deployer/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# --- END NVM ---

# --- START ENV ---
# Source .env file for environment variables
# This is required because SSH forced command in authorized_keys
# prevents environment variables from being passed via the SSH session
if [ -f /var/www/sontra/.env ]; then
    set -a
    source /var/www/sontra/.env
    set +a
else
    echo -e "${RED}❌ Error: /var/www/sontra/.env file not found${NC}"
    exit 1
fi
# --- END ENV ---

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

# ===== START: Validate environment variables =====
echo -e "${YELLOW}🔐 Validating environment variables...${NC}"

if [ -z "$RESEND_API_KEY" ]; then
    echo -e "${RED}❌ Error: RESEND_API_KEY not set${NC}"
    exit 1
fi

if [ -z "$RESEND_EMAIL_DOMAIN" ]; then
    echo -e "${RED}❌ Error: RESEND_EMAIL_DOMAIN not set${NC}"
    exit 1
fi

if [ -z "$TARGET_INBOX" ]; then
    echo -e "${RED}❌ Error: TARGET_INBOX not set${NC}"
    exit 1
fi
if [ -z "$N8N_DEMO_CALL_WEBHOOK" ]; then
    echo -e "${RED}❌ Error: N8N_DEMO_CALL_WEBHOOK not set${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Environment variables validated${NC}"

# Export for docker-compose to use
export RESEND_API_KEY
export RESEND_EMAIL_DOMAIN
export TARGET_INBOX
export N8N_DEMO_CALL_WEBHOOK
# ===== END Validate environment variables =====

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

# Build new Docker image (ONLY for astro-web)
echo -e "${YELLOW}🔨 Building Docker image for Astro website...${NC}"
# only use --no-cache flag on FORCE_REBUILD
if [ "$FORCE_REBUILD" = true ]; then
    echo -e "${YELLOW}🔨 Force rebuild (no cache)...${NC}"
    docker compose build --no-cache astro-web
else
    echo -e "${YELLOW}🔨 Building (with cache)...${NC}"
    docker compose build astro-web
fi

# Stop ONLY the astro-web container (keeps n8n running!)
echo -e "${YELLOW}🛑 Stopping Astro container (n8n stays running)...${NC}"
docker compose stop astro-web
docker compose rm -f astro-web

# Start new Astro container (n8n remains untouched)
echo -e "${YELLOW}🚀 Starting new Astro container...${NC}"
docker compose up -d astro-web

# Ensure n8n is running (start if not, but don't restart if already up)
echo -e "${YELLOW}🔄 Ensuring n8n is running...${NC}"
docker compose up -d n8n

# Wait for container to be ready with proper health check
echo -e "${YELLOW}⏳ Waiting for Astro container to be ready...${NC}"

MAX_WAIT=120  # Maximum wait time in seconds (2 minutes)
WAIT_INTERVAL=3  # Check every 3 seconds
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
    # Check if container is running
    if docker compose ps | grep -q "sontra-website.*Up"; then
        # Container is up, now check if it's actually responding
        if curl -f -s -o /dev/null http://localhost:4321; then
            echo -e "${GREEN}✅ Astro container is ready and responding!${NC}"
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
if docker compose ps | grep -q "sontra-website.*Up" && curl -f -s -o /dev/null http://localhost:4321; then
    echo -e "${GREEN}✅ Deployment successful!${NC}"
    echo -e "${GREEN}🌐 Site is live at https://sontra.dev${NC}"
    
    # Check n8n status unaffected
    if docker compose ps | grep -q "n8n.*Up"; then
        echo -e "${GREEN}✅ n8n is running at https://n8n.sontra.dev${NC}"
    else
        echo -e "${YELLOW}⚠️  n8n is not running (may need manual start)${NC}"
    fi
    
    # Show recent commits
    echo -e "${YELLOW}📝 Recent commits:${NC}"
    cd /var/www/sontra/sontra-website
    git log --oneline -3
    
    # Show logs for Astro only
    echo -e "${YELLOW}📋 Recent Astro container logs:${NC}"
    cd /var/www/sontra
    docker compose logs --tail=20 astro-web

    # Optional: Prune old images (uncomment if desired)
    # echo -e "${YELLOW}🧹 Cleaning up old Docker images...${NC}"
    # docker image prune -f --filter "until=24h"
    # echo -e "${GREEN}✅ Cleanup complete${NC}"
    
    exit 0
else
    # Rollback to previous commit
    echo -e "${RED}❌ Deployment failed! Container is not responding after ${MAX_WAIT} seconds.${NC}"
    echo -e "${YELLOW}📋 Container logs:${NC}"
    docker compose logs --tail=50 astro-web
    
    echo -e "${YELLOW}🔄 Rolling back to previous commit...${NC}"
    
    cd /var/www/sontra/sontra-website
    git reset --hard "$PREVIOUS_COMMIT"
    cd /var/www/sontra

    docker compose build astro-web
    docker compose stop astro-web
    docker compose rm -f astro-web
    docker compose up -d astro-web
    
    # Wait for rollback container to start
    echo -e "${YELLOW}⏳ Waiting for rollback to complete...${NC}"
    sleep 10
    
    if docker compose ps | grep -q "sontra-website.*Up" && curl -f -s -o /dev/null http://localhost:4321; then
        echo -e "${GREEN}✅ Successfully rolled back to ${PREVIOUS_COMMIT}${NC}"
    else
        echo -e "${RED}❌ Rollback failed! Manual intervention required.${NC}"
        echo -e "${RED}📋 Check deployment logs and contact the administrator${NC}"
    fi
    
    exit 1
fi