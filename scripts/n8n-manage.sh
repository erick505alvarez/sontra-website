#!/bin/bash
#==============================================================================
# n8n Management Script
#==============================================================================
# Location: /home/deployer/n8n-manage.sh
# Purpose:  Manage n8n automation platform independently from Astro deployments
# Author:   Sontra DevOps Team
# Usage:    ./n8n-manage.sh {start|stop|restart|update|logs|status|backup}
#
# IMPORTANT: This script manages ONLY n8n, not the Astro website
# The Astro deployment script (deploy.sh) handles the website separately
#
# Expected Commands:
#   As deployer user:  /home/deployer/n8n-manage.sh [command]
#   As erick user:     sudo -u deployer /home/deployer/n8n-manage.sh [command]
#
# Examples:
#   /home/deployer/n8n-manage.sh start    # Start n8n
#   /home/deployer/n8n-manage.sh status   # Check if n8n is running
#   /home/deployer/n8n-manage.sh logs     # View live logs
#   /home/deployer/n8n-manage.sh backup   # Create backup before updates
#==============================================================================

# Exit immediately if any command fails
set -e

#==============================================================================
# Configuration
#==============================================================================

# ANSI color codes for pretty output
RED='\033[0;31m'      # Error messages
GREEN='\033[0;32m'    # Success messages
YELLOW='\033[1;33m'   # Info/warning messages
BLUE='\033[0;34m'     # General info
NC='\033[0m'          # No Color (reset)

# Change to docker-compose directory
# This is where docker-compose.yml and .env files are located
cd /var/www/sontra || exit 1

case "$1" in
    #==========================================================================
    # START - Start the n8n container
    #==========================================================================
    # What this does:
    #   1. Starts the n8n container in detached mode (-d)
    #   2. If container exists but is stopped, it starts it
    #   3. If container doesn't exist, it creates and starts it
    #   4. Pulls n8n image if not already downloaded
    #
    # Expected command:
    #   /home/deployer/n8n-manage.sh start
    #
    # When to use:
    #   - After VPS reboot (if container didn't auto-start)
    #   - After manually stopping n8n
    #   - First time setup
    #
    # Docker command executed:
    #   docker compose up -d n8n
    #
    # Notes:
    #   - Does NOT rebuild the image (uses existing)
    #   - Does NOT restart if already running
    #   - Safe to run multiple times (idempotent)
    #==========================================================================
    start)
        echo -e "${YELLOW}🚀 Starting n8n...${NC}"
        docker compose up -d n8n
        echo -e "${GREEN}✅ n8n started${NC}"
        echo -e "${GREEN}🌐 Access at: https://n8n.sontra.dev${NC}"
        ;;
    
    #==========================================================================
    # STOP - Stop the n8n container gracefully
    #==========================================================================
    # What this does:
    #   1. Sends SIGTERM to n8n process (graceful shutdown)
    #   2. Waits for n8n to finish current operations
    #   3. Stops the container (does NOT remove it)
    #   4. Data volume remains intact
    #
    # Expected command:
    #   /home/deployer/n8n-manage.sh stop
    #
    # When to use:
    #   - Before server maintenance
    #   - When troubleshooting issues
    #   - Before manual backup operations
    #   - Rarely needed (n8n should run 24/7)
    #
    # Docker command executed:
    #   docker compose stop n8n
    #
    # Important notes:
    #   - Running workflows will be interrupted!
    #   - Scheduled workflows won't run while stopped
    #   - Container will auto-restart on VPS reboot (restart: always)
    #   - To permanently disable, use: docker compose down n8n
    #==========================================================================
    stop)
        echo -e "${YELLOW}🛑 Stopping n8n...${NC}"
        docker compose stop n8n
        echo -e "${GREEN}✅ n8n stopped${NC}"
        ;;
    
    #==========================================================================
    # RESTART - Restart the n8n container
    #==========================================================================
    # What this does:
    #   1. Stops the n8n container gracefully (SIGTERM)
    #   2. Starts the container again with same configuration
    #   3. Uses existing image (does NOT pull updates)
    #   4. Preserves all data in volume
    #
    # Expected command:
    #   /home/deployer/n8n-manage.sh restart
    #
    # When to use:
    #   - After changing environment variables in .env
    #   - When n8n is unresponsive but container is running
    #   - After modifying docker-compose.yml
    #   - When troubleshooting workflow issues
    #
    # Docker command executed:
    #   docker compose restart n8n
    #
    # Important notes:
    #   - Running workflows will be interrupted!
    #   - Downtime is typically 5-10 seconds
    #   - Does NOT update n8n version (use 'update' for that)
    #   - Equivalent to: stop + start
    #==========================================================================
    restart)
        echo -e "${YELLOW}🔄 Restarting n8n...${NC}"
        docker compose restart n8n
        echo -e "${GREEN}✅ n8n restarted${NC}"
        ;;
    
    #==========================================================================
    # UPDATE - Update n8n to the latest version
    #==========================================================================
    # What this does:
    #   1. Pulls the latest n8n:latest image from Docker Hub
    #   2. Stops the current n8n container
    #   3. Removes the old container
    #   4. Creates new container with updated image
    #   5. Starts the new container
    #   6. Preserves all data (workflows, credentials, users)
    #
    # Expected command:
    #   /home/deployer/n8n-manage.sh update
    #
    # When to use:
    #   - Monthly (check n8n release notes first)
    #   - When new features are needed
    #   - When security patches are released
    #   - After creating a backup
    #
    # Docker commands executed:
    #   docker compose pull n8n      # Downloads latest image
    #   docker compose up -d n8n     # Recreates container
    #
    # IMPORTANT - Before updating:
    #   1. Create backup: ./n8n-manage.sh backup
    #   2. Check release notes: https://github.com/n8n-io/n8n/releases
    #   3. Schedule during low-traffic time
    #   4. Expect 30-60 seconds of downtime
    #
    # Rollback if issues:
    #   docker compose down n8n
    #   docker tag n8nio/n8n:latest n8nio/n8n:backup
    #   docker compose up -d n8n
    #
    # Notes:
    #   - Data volume is preserved (workflows, credentials, etc.)
    #   - Environment variables remain unchanged
    #   - Running workflows will be interrupted
    #==========================================================================
    update)
        echo -e "${YELLOW}📦 Updating n8n to latest version...${NC}"
        docker compose pull n8n
        docker compose up -d n8n
        echo -e "${GREEN}✅ n8n updated${NC}"
        ;;
    
    #==========================================================================
    # LOGS - View n8n container logs in real-time
    #==========================================================================
    # What this does:
    #   1. Displays recent n8n logs from Docker
    #   2. Follows logs in real-time (like tail -f)
    #   3. Shows all container output (stdout + stderr)
    #   4. Press Ctrl+C to exit (doesn't stop container)
    #
    # Expected command:
    #   /home/deployer/n8n-manage.sh logs
    #
    # When to use:
    #   - Troubleshooting workflow failures
    #   - Monitoring n8n startup
    #   - Debugging API errors
    #   - Checking for warnings/errors
    #   - Monitoring webhook activity
    #
    # Docker command executed:
    #   docker compose logs -f n8n
    #
    # What you'll see:
    #   - Workflow execution logs
    #   - HTTP request logs (webhooks, API calls)
    #   - Error messages and stack traces
    #   - Startup/shutdown messages
    #   - Database queries (if debug enabled)
    #
    # Useful variations (run these manually if needed):
    #   docker compose logs --tail=100 n8n     # Last 100 lines only
    #   docker compose logs --since=1h n8n     # Last hour only
    #   docker compose logs n8n | grep ERROR   # Filter errors only
    #   docker compose logs --timestamps n8n   # Show timestamps
    #
    # Notes:
    #   - Logs are NOT persisted (lost on container removal)
    #   - Press Ctrl+C to exit (container keeps running)
    #   - For persistent logs, configure n8n to write to files
    #==========================================================================
    logs)
        echo -e "${YELLOW}📋 n8n logs (Ctrl+C to exit):${NC}"
        docker compose logs -f n8n
        ;;
    
    #==========================================================================
    # STATUS - Check n8n health and availability
    #==========================================================================
    # What this does:
    #   1. Shows container status (Up/Down, uptime)
    #   2. Checks if n8n is responding to HTTP requests
    #   3. Tests the /healthz endpoint
    #   4. Reports overall health status
    #
    # Expected command:
    #   /home/deployer/n8n-manage.sh status
    #
    # When to use:
    #   - Quick health check
    #   - After starting/restarting n8n
    #   - Monitoring scripts/cron jobs
    #   - Troubleshooting connectivity issues
    #   - Before running updates
    #
    # Docker/Curl commands executed:
    #   docker compose ps n8n                    # Container status
    #   curl -f -s http://localhost:5678/healthz # Health check
    #
    # Status outputs:
    #   Container "Up" + Healthy = ✅ Everything working
    #   Container "Up" + Not responding = ⚠️ Container running but n8n crashed
    #   Container not listed = ❌ Container not running at all
    #
    # What the health check tests:
    #   - n8n web server is running
    #   - n8n can accept HTTP connections
    #   - Port 5678 is accessible
    #   - Basic n8n process is alive
    #
    # Troubleshooting:
    #   If unhealthy:
    #     1. Check logs: ./n8n-manage.sh logs
    #     2. Check resources: docker stats n8n
    #     3. Restart: ./n8n-manage.sh restart
    #     4. Check .env variables are correct
    #
    # Note: This checks localhost:5678 (internal)
    #       To test external access, visit: https://n8n.sontra.dev
    #==========================================================================
    status)
        echo -e "${YELLOW}🏥 n8n status:${NC}"
        docker compose ps n8n
        echo ""
        if curl -f -s -o /dev/null http://localhost:5678/healthz; then
            echo -e "${GREEN}✅ n8n is healthy and responding${NC}"
        else
            echo -e "${RED}❌ n8n is not responding${NC}"
        fi
        ;;
    
    #==========================================================================
    # BACKUP - Create a complete backup of n8n data
    #==========================================================================
    # What this does:
    #   1. Creates a timestamped backup of the n8n_data volume
    #   2. Backs up: workflows, credentials, users, executions, settings
    #   3. Saves as compressed tar.gz file
    #   4. Stores in /var/www/sontra/backups/n8n/
    #
    # Expected command:
    #   /home/deployer/n8n-manage.sh backup
    #
    # When to use:
    #   - BEFORE updating n8n (critical!)
    #   - Weekly/monthly (regular backups)
    #   - Before major workflow changes
    #   - Before server migrations
    #   - After creating important workflows
    #
    # What gets backed up:
    #   - database.sqlite (users, workflows, credentials, executions)
    #   - .n8n/ configuration files
    #   - All workflow data
    #   - User accounts (hashed passwords)
    #   - API credentials (encrypted)
    #   - Execution history
    #
    # What does NOT get backed up:
    #   - Docker image itself (can be re-pulled)
    #   - docker-compose.yml (managed separately in git)
    #   - .env file (managed separately)
    #   - nginx configuration (managed separately)
    #
    # Docker command executed:
    #   docker run --rm \
    #     -v n8n_data:/data \
    #     -v /var/www/sontra/backups:/backup \
    #     alpine tar czf /backup/n8n-backup-TIMESTAMP.tar.gz -C /data .
    #
    # How it works:
    #   1. Spins up temporary Alpine Linux container
    #   2. Mounts n8n_data volume as /data (read-only)
    #   3. Mounts backup directory as /backup
    #   4. Creates compressed tarball of all data
    #   5. Container removes itself (--rm flag)
    #
    # Backup file format:
    #   n8n-backup-YYYYMMDD-HHMMSS.tar.gz
    #   Example: n8n-backup-20241207-143022.tar.gz
    #
    # Backup location:
    #   /var/www/sontra/backups/n8n/n8n-backup-TIMESTAMP.tar.gz
    #
    # To restore a backup:
    #   1. Stop n8n: ./n8n-manage.sh stop
    #   2. Extract backup:
    #      docker run --rm \
    #        -v n8n_data:/data \
    #        -v /var/www/sontra/backups:/backup \
    #        alpine sh -c "rm -rf /data/* && tar xzf /backup/BACKUP_FILE.tar.gz -C /data"
    #   3. Start n8n: ./n8n-manage.sh start
    #
    # Best practices:
    #   - Keep at least 3 recent backups
    #   - Copy backups off-server (to S3, local machine, etc.)
    #   - Test restore process periodically
    #   - Backup before ANY updates or major changes
    #   - Automate with cron: 0 2 * * 0 /home/deployer/n8n-manage.sh backup
    #
    # Security notes:
    #   - Backups contain encrypted credentials
    #   - Backups contain hashed passwords
    #   - Store backups securely (they're sensitive!)
    #   - Set proper permissions: chmod 600 on backup files
    #
    # Disk space:
    #   - Check available space: df -h /var/www/sontra/backups
    #   - Typical backup size: 10-100MB (depends on executions stored)
    #   - Compressed ratio: ~70% (tar.gz)
    #==========================================================================
    backup)
        echo -e "${YELLOW}💾 Creating n8n backup...${NC}"
        BACKUP_DIR="/var/www/sontra/backups/n8n"
        BACKUP_FILE="n8n-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
        
        # Create backup directory if it doesn't exist
        mkdir -p "$BACKUP_DIR"
        
        # Backup the n8n data volume using a temporary Alpine container
        # --rm: Remove container after backup completes
        # -v n8n_data:/data: Mount n8n volume as /data
        # -v $BACKUP_DIR:/backup: Mount backup directory
        # alpine: Lightweight Linux image (5MB)
        # tar czf: Create compressed tarball
        docker run --rm \
            -v n8n_data:/data \
            -v "$BACKUP_DIR:/backup" \
            alpine \
            tar czf "/backup/$BACKUP_FILE" -C /data .
        
        echo -e "${GREEN}✅ Backup created: $BACKUP_DIR/$BACKUP_FILE${NC}"
        echo -e "${BLUE}ℹ️  Keep backups in a secure location${NC}"
        ;;
    
    #==========================================================================
    # HELP - Show usage information (default if no valid command)
    #==========================================================================
    # This section runs when:
    #   - No command is provided: ./n8n-manage.sh
    #   - Invalid command: ./n8n-manage.sh invalidcommand
    #   - Help requested: ./n8n-manage.sh help
    #
    # Displays:
    #   - Script usage syntax
    #   - Available commands
    #   - Brief description of each command
    #
    # Exit code: 1 (indicates error/no action taken)
    #==========================================================================
    *)
        echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║         n8n Automation Platform - Management Script       ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}Usage:${NC}"
        echo "  $0 {start|stop|restart|update|logs|status|backup}"
        echo ""
        echo -e "${YELLOW}Commands:${NC}"
        echo "  start    - Start n8n container"
        echo "             Use when: After VPS reboot, first setup, after manual stop"
        echo ""
        echo "  stop     - Stop n8n container (graceful shutdown)"
        echo "             Use when: Server maintenance, troubleshooting (rare)"
        echo ""
        echo "  restart  - Restart n8n container"
        echo "             Use when: After .env changes, troubleshooting issues"
        echo ""
        echo "  update   - Pull latest n8n version and restart"
        echo "             Use when: Monthly updates, new features needed"
        echo "             IMPORTANT: Run 'backup' command BEFORE updating!"
        echo ""
        echo "  logs     - View n8n logs in real-time (Ctrl+C to exit)"
        echo "             Use when: Troubleshooting, monitoring workflows"
        echo ""
        echo "  status   - Check n8n health and container status"
        echo "             Use when: Quick health check, monitoring"
        echo ""
        echo "  backup   - Create timestamped backup of n8n data"
        echo "             Use when: Before updates, weekly, before big changes"
        echo ""
        echo -e "${YELLOW}Examples:${NC}"
        echo "  $0 status              # Check if n8n is running"
        echo "  $0 backup              # Create backup"
        echo "  $0 update              # Update to latest version"
        echo "  $0 logs                # Watch logs (Ctrl+C to exit)"
        echo ""
        echo -e "${YELLOW}Important Notes:${NC}"
        echo "  • This script manages ONLY n8n (not Astro website)"
        echo "  • Always backup before updating!"
        echo "  • n8n accessible at: https://n8n.sontra.dev"
        echo "  • Data stored in Docker volume: n8n_data"
        echo "  • Backups stored in: /var/www/sontra/backups/n8n/"
        echo ""
        exit 1
        ;;
esac