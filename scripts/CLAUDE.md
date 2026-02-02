# CI/CD Deployment Flow Documentation

## Overview

This document traces the environment variable flow through the CI/CD pipeline to diagnose deployment issues.

## Architecture

```
GitHub Push to main
       ↓
GitHub Actions (deploy.yml)
       ↓ (SSH via appleboy/ssh-action)
VPS: /home/deployer/deploy.sh  ← CRITICAL: This is a SEPARATE file from scripts/deploy.sh
       ↓
VPS: docker compose up (reads .env file)
       ↓
Container: check-env.js validates env vars
       ↓
Container: Astro app runs with env vars
```

## Key Files and Their Locations

| File               | Location                             | Purpose                       |
| ------------------ | ------------------------------------ | ----------------------------- |
| deploy.yml         | `.github/workflows/deploy.yml`       | GitHub Actions workflow       |
| deploy.sh (repo)   | `scripts/deploy.sh`                  | Deploy script in git repo     |
| deploy.sh (VPS)    | `/home/deployer/deploy.sh`           | **Actual script GitHub runs** |
| .env (VPS)         | `/var/www/sontra/.env`               | Docker Compose env vars       |
| docker-compose.yml | `/var/www/sontra/docker-compose.yml` | Container orchestration       |

## CRITICAL ISSUE IDENTIFIED

**There are TWO deploy.sh files:**

1. `scripts/deploy.sh` - In the git repo, gets updated with commits
2. `/home/deployer/deploy.sh` - On VPS, **manually maintained**, what GitHub Actions actually runs

When you update `scripts/deploy.sh` in the repo, **the VPS copy at `/home/deployer/deploy.sh` is NOT automatically updated**.

## Environment Variable Flow

### 1. GitHub Actions (deploy.yml)

```yaml
script: |
  export RESEND_API_KEY="${{ secrets.RESEND_API_KEY }}"
  export RESEND_EMAIL_DOMAIN="${{ secrets.RESEND_EMAIL_DOMAIN }}"
  export TARGET_INBOX="${{ secrets.TARGET_INBOX }}"
  export N8N_DEMO_CALL_WEBHOOK="${{ secrets.N8N_DEMO_CALL_WEBHOOK }}"
  bash /home/deployer/deploy.sh
```

GitHub Actions substitutes `${{ secrets.X }}` with actual values before sending to VPS.

### 2. VPS deploy.sh

The script at `/home/deployer/deploy.sh` validates these env vars:

```bash
if [ -z "$RESEND_API_KEY" ]; then
    echo -e "${RED}❌ Error: RESEND_API_KEY not set${NC}"
    exit 1
fi
```

Then re-exports them for docker-compose:

```bash
export RESEND_API_KEY
export RESEND_EMAIL_DOMAIN
export TARGET_INBOX
export N8N_DEMO_CALL_WEBHOOK
```

### 3. Docker Compose

`docker-compose.yml` uses shell variable substitution:

```yaml
environment:
  - RESEND_API_KEY=${RESEND_API_KEY}
```

Docker Compose reads from:

1. Shell environment (from exports)
2. `.env` file in same directory as docker-compose.yml

### 4. Container

`scripts/check-env.js` runs at container startup and validates `process.env`.

## Why "RESEND_API_KEY not set" Error?

The `appleboy/ssh-action` executes commands via SSH. The `export` commands and `bash deploy.sh` run in the same SSH session, so exports SHOULD be inherited.

**Possible causes:**

1. **The `envs` parameter matters** - The old working config had `envs: RESEND_API_KEY,...`. This parameter may affect how the action handles the script execution context.

2. **Shell compatibility** - The ssh-action may use `/bin/sh` instead of `/bin/bash`, and export behavior differs.

3. **VPS deploy.sh is outdated** - If `/home/deployer/deploy.sh` differs from the repo version.

## Solution Options

### Option A: Restore envs parameter (try first)

```yaml
envs: RESEND_API_KEY,RESEND_EMAIL_DOMAIN,TARGET_INBOX,N8N_DEMO_CALL_WEBHOOK
script: |
  export RESEND_API_KEY="${{ secrets.RESEND_API_KEY }}"
  ...
```

### Option B: Source .env file in deploy.sh

Add to `/home/deployer/deploy.sh` after the NVM section:

```bash
# Source .env file for environment variables
if [ -f /var/www/sontra/.env ]; then
    set -a
    source /var/www/sontra/.env
    set +a
fi
```

This makes deploy.sh self-contained - it reads from the VPS .env file directly, not relying on GitHub exports.

### Option C: Pass env vars inline

```yaml
script: |
  RESEND_API_KEY="${{ secrets.RESEND_API_KEY }}" \
  RESEND_EMAIL_DOMAIN="${{ secrets.RESEND_EMAIL_DOMAIN }}" \
  TARGET_INBOX="${{ secrets.TARGET_INBOX }}" \
  N8N_DEMO_CALL_WEBHOOK="${{ secrets.N8N_DEMO_CALL_WEBHOOK }}" \
  bash /home/deployer/deploy.sh
```

## Do You Need Both GitHub Secrets AND VPS .env?

**Short answer: You only need ONE, not both.**

### Why they exist:

| Source         | Purpose                                  | When Used         |
| -------------- | ---------------------------------------- | ----------------- |
| GitHub Secrets | Pass secrets to deploy.sh for validation | During deployment |
| VPS .env file  | Docker Compose variable substitution     | Container startup |

### Current redundancy:

1. GitHub exports secrets → deploy.sh validates → re-exports
2. Docker Compose reads from shell environment
3. BUT docker-compose.yml ALSO reads from .env file

### Recommended approach:

**Use the VPS .env file as single source of truth:**

1. Keep secrets in VPS `/var/www/sontra/.env` (you already have this)
2. Have deploy.sh source this file instead of expecting GitHub exports
3. Remove the GitHub export commands (they become unnecessary)
4. Keep GitHub secrets only for VPS_HOST, VPS_USERNAME, VPS_SSH_KEY

This simplifies the flow and eliminates the export inheritance issue.

## Action Items

1. **Immediate fix**: SSH into VPS and update `/home/deployer/deploy.sh` to source the .env file
2. **Verify**: Check that `/var/www/sontra/.env` contains all 4 required variables
3. **Simplify**: Consider removing GitHub secret exports since .env file has the values

## Commands to Debug

```bash
# SSH to VPS and check .env contents
ssh deployer@your-vps
cat /var/www/sontra/.env

# Check what deploy.sh version is on VPS
cat /home/deployer/deploy.sh | head -60

# Manually test sourcing .env
source /var/www/sontra/.env
echo $RESEND_API_KEY  # Should show value
```
