# CI/CD Deployment Documentation

## Overview

This document explains how the CI/CD pipeline deploys the Sontra website from GitHub to a DigitalOcean VPS, including how secrets are managed and passed to Docker containers.

## Architecture

```
GitHub (main branch)
       │
       ▼ (push triggers workflow)
GitHub Actions (.github/workflows/deploy.yml)
       │
       ▼ (SSH connection via appleboy/ssh-action)
VPS: SSH forced command runs /home/deployer/deploy.sh
       │
       ▼ (sources /var/www/sontra/.env)
VPS: deploy.sh has environment variables
       │
       ▼ (docker compose up)
Docker: Containers receive env vars from shell
       │
       ▼ (Astro checks process.env)
Container: scripts/check-env.js validates secrets
       │
       ▼
Container: Astro app runs with secrets available
```

## Key Files

| File                 | Location                             | Purpose                                                      |
| -------------------- | ------------------------------------ | ------------------------------------------------------------ |
| `deploy.yml`         | `.github/workflows/deploy.yml`       | GitHub Actions workflow                                      |
| `deploy.sh`          | `/home/deployer/deploy.sh` (VPS)     | Deployment script (manually synced from `scripts/deploy.sh`) |
| `.env`               | `/var/www/sontra/.env` (VPS)         | Production secrets                                           |
| `docker-compose.yml` | `/var/www/sontra/docker-compose.yml` | Container orchestration                                      |
| `check-env.js`       | `scripts/check-env.js`               | Validates env vars at container startup                      |

## Secrets Management

### Where Secrets Live

**Production secrets are stored in `/var/www/sontra/.env` on the VPS.** This is the single source of truth.

```bash
# /var/www/sontra/.env
RESEND_API_KEY=re_xxxx
RESEND_EMAIL_DOMAIN=sontra.dev
TARGET_INBOX=hello@sontra.dev
N8N_DEMO_CALL_WEBHOOK=https://n8n.sontra.dev/webhook/xxxx
```

### Why Not Pass Secrets via GitHub?

The SSH key uses a **forced command** for security:

```
# /home/deployer/.ssh/authorized_keys
restrict,command="/home/deployer/deploy.sh" ssh-ed25519 AAAA...
```

This means:

- SSH connections can ONLY run `/home/deployer/deploy.sh`
- Any command GitHub sends is ignored (including environment variables)
- This is a security feature that limits what the deploy key can do

### How Secrets Reach Docker

1. **deploy.sh sources the .env file:**

   ```bash
   if [ -f /var/www/sontra/.env ]; then
       set -a  # Auto-export all variables
       source /var/www/sontra/.env
       set +a
   fi
   ```

2. **docker-compose.yml uses shell variable substitution:**

   ```yaml
   environment:
     - RESEND_API_KEY=${RESEND_API_KEY}
     - RESEND_EMAIL_DOMAIN=${RESEND_EMAIL_DOMAIN}
     - TARGET_INBOX=${TARGET_INBOX}
     - N8N_DEMO_CALL_WEBHOOK=${N8N_DEMO_CALL_WEBHOOK}
   ```

3. **Container validates at startup** via `check-env.js`

## Deployment Flow

### 1. Push to Main

```bash
git push origin main
```

### 2. GitHub Actions Triggers

`.github/workflows/deploy.yml` runs:

- Connects to VPS via SSH
- SSH forced command executes `/home/deployer/deploy.sh`

### 3. deploy.sh Executes

1. Loads NVM for Node.js
2. Sources `/var/www/sontra/.env` for secrets
3. Validates all required env vars are set
4. Pulls latest code from GitHub
5. Builds Docker image (`docker compose build astro-web`)
6. Restarts container (`docker compose up -d astro-web`)
7. Waits for health check
8. Rolls back if deployment fails

### 4. Container Starts

1. `check-env.js` validates `process.env` has all required secrets
2. Astro server starts on port 4321
3. NGINX proxies traffic to the container

## Adding a New Secret

When adding a new environment variable:

1. **Add to VPS .env file:**

   ```bash
   ssh deployer@your-vps
   vim /var/www/sontra/.env
   # Add: NEW_SECRET=value
   ```

2. **Add to docker-compose.yml** (both files):

   ```yaml
   # docker-compose.yml and docker-compose.dev.yml
   environment:
     - NEW_SECRET=${NEW_SECRET}
   ```

3. **Add to Astro env schema** (`astro.config.mjs`):

   ```javascript
   NEW_SECRET: envField.string({
     context: "server",
     access: "secret",
     optional: false,
   }),
   ```

4. **Add to check-env.js:**

   ```javascript
   const requiredSecrets = [
     // ... existing
     "NEW_SECRET",
   ];
   ```

5. **Add to deploy.sh validation:**

   ```bash
   if [ -z "$NEW_SECRET" ]; then
       echo -e "${RED}❌ Error: NEW_SECRET not set${NC}"
       exit 1
   fi
   ```

6. **Update .env.example** for documentation

7. **Sync deploy.sh to VPS:**
   ```bash
   scp scripts/deploy.sh deployer@your-vps:/home/deployer/deploy.sh
   ```

## Troubleshooting

### "Error: VARIABLE not set"

The variable is missing from `/var/www/sontra/.env` on the VPS. SSH in and add it.

### ".env file not found"

The `.env` file doesn't exist at `/var/www/sontra/.env`. Create it with all required secrets.

### Deployment succeeds but app crashes

Check container logs:

```bash
ssh deployer@your-vps
cd /var/www/sontra
docker compose logs astro-web
```

### Changes to deploy.sh not taking effect

The VPS uses `/home/deployer/deploy.sh`, not the repo version. Manually sync:

```bash
scp scripts/deploy.sh deployer@your-vps:/home/deployer/deploy.sh
```

## Security Notes

- **Forced command** in authorized_keys limits the SSH key to only run deploy.sh
- **Secrets never pass through GitHub Actions** - they stay on the VPS
- **GitHub secrets** (VPS_HOST, VPS_USERNAME, VPS_SSH_KEY) are only for SSH connection
- **.env file** has restricted permissions (`chmod 600`)
