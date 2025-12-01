# DigitalOcean Deployment Guide

This guide explains how to deploy your Astro website with API routes to a DigitalOcean droplet.

## Configuration Changes Made

1. **Installed Node.js adapter**: `@astrojs/node` - Enables server-side rendering and API routes
2. **Updated `astro.config.mjs`**: Added `output: "server"` and Node.js adapter configuration
3. **Added start script**: `npm start` - Runs the production server

## Build Process

```bash
# Build the application
npm run build

# This creates:
# - dist/server/entry.mjs (Node.js server entry point)
# - dist/client/ (static assets)
```

## Deployment Steps on DigitalOcean

### 1. Set Up Your Droplet

```bash
# SSH into your droplet
ssh root@your-droplet-ip

# Update system
apt update && apt upgrade -y

# Install Node.js (v20 or later recommended)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install PM2 (process manager)
npm install -g pm2

# Install nginx (reverse proxy)
apt install -y nginx
```

### 2. Deploy Your Application

```bash
# Clone your repository
git clone your-repo-url /var/www/sontra-website
cd /var/www/sontra-website

# Install dependencies
npm install --production

# Build the application
npm run build

# Set environment variables
nano .env
# Add: RESEND_API_KEY=your_key_here

# Start with PM2
pm2 start npm --name "sontra-website" -- start
pm2 save
pm2 startup  # Follow instructions to enable auto-start on boot
```

### 3. Configure Nginx Reverse Proxy

Create `/etc/nginx/sites-available/sontra-website`:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
        proxy_pass http://localhost:4321;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable the site:

```bash
ln -s /etc/nginx/sites-available/sontra-website /etc/nginx/sites-enabled/
nginx -t  # Test configuration
systemctl restart nginx
```

### 4. Set Up SSL with Let's Encrypt

```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d your-domain.com -d www.your-domain.com
```

### 5. Environment Variables

Make sure to set your environment variables on the server:

```bash
# In your project directory
echo "RESEND_API_KEY=your_actual_key" > .env

# Or use PM2 ecosystem file (recommended)
pm2 ecosystem
# Edit ecosystem.config.js to include env variables
```

## Important Notes

- **Port**: The Node.js server runs on port `4321` by default (configurable via `PORT` env variable)
- **Process Management**: PM2 keeps your app running and restarts it if it crashes
- **Static Assets**: Astro serves static assets efficiently through the Node.js server
- **API Routes**: Your `/api/contact` endpoint will work at `https://your-domain.com/api/contact`

## Updating Your Application

```bash
cd /var/www/sontra-website
git pull
npm install --production
npm run build
pm2 restart sontra-website
```

## Monitoring

```bash
# View logs
pm2 logs sontra-website

# Monitor resources
pm2 monit

# View status
pm2 status
```
