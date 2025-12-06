# Dockerfile (Production) - for VPS deployment and local testing
# This is optimized for production: small, secure, fast
# Safe to test in development - all changes are isolated inside the container

# Stage 1: Base image with Node.js
# Use Alpine Linux for smaller image size (~40MB vs ~300MB for full Node)
# node:20-alpine uses Node.js version 20 LTS
FROM node:20-alpine AS base

# Stage 2: Install production dependencies only
FROM base AS deps
# libc6-compat is needed for some npm packages that use native bindings
RUN apk add --no-cache libc6-compat
# Set working directory - all subsequent commands run from here
WORKDIR /app

# Copy only package files first (Docker caching optimization)
# If these files don't change, Docker reuses this layer instead of reinstalling
COPY package*.json ./
# npm ci is faster and more reliable than npm install for production
# --only=production skips devDependencies (saves space and time)
# --ignore-scripts to ignore husky
RUN npm ci --only=production --ignore-scripts

# Stage 3: Build the Astro application
FROM base AS builder
WORKDIR /app
# Copy node_modules from deps stage (avoids reinstalling)
COPY --from=deps /app/node_modules ./node_modules
# Copy all source code (Astro project files)
# Make sure you have a .dockerignore file to exclude node_modules, .git, etc.
COPY . .

# Build Astro site for production
# This runs the "build" script from package.json
# Creates the dist/ folder with SSR server
RUN npm run build

# Stage 4: Production runtime image (smallest possible)
FROM base AS runner
WORKDIR /app

# ENV variables in the Dockerfile are DEFAULT VALUES
# They provide fallbacks if docker-compose.yml doesn't override them
# docker-compose.yml will override these with values from .env file
# Think of these as "hard-coded defaults" that get replaced at runtime

# NODE_ENV default - docker-compose.yml will set this to "production"
ENV NODE_ENV=production

# PORT default - docker-compose.yml will set this to 4321
ENV PORT=4321

# HOST default - CRITICAL for Docker networking
# This is the ONLY env var that really matters in the Dockerfile
# It MUST be 0.0.0.0 so the container accepts connections from outside
# docker-compose.yml will also set this, but having it here ensures it's always set
ENV HOST=0.0.0.0

# Create non-root user for security
# These commands run INSIDE the container, NOT on Mac/VPS
# They create a user within the isolated container filesystem
# addgroup creates a system group with GID 1001 inside the container
RUN addgroup --system --gid 1001 nodejs
# adduser creates a system user with UID 1001 inside the container
RUN adduser --system --uid 1001 astro

# Copy only the built application from builder stage
# --chown sets ownership to astro:nodejs user/group (inside container only)
# dist/ contains built Astro SSR server
COPY --from=builder --chown=astro:nodejs /app/dist ./dist
# node_modules needed to run the server (not for building)
COPY --from=builder --chown=astro:nodejs /app/node_modules ./node_modules
# package.json needed if start script references it
COPY --from=builder --chown=astro:nodejs /app/package.json ./package.json

# Switch to non-root user (security best practice)
# All subsequent commands run as this user inside the container
USER astro

# Document which port the container listens on (doesn't actually publish it)
# This is for documentation - the actual port mapping is in docker-compose.yml
EXPOSE 4321

# Start the Astro SSR server
# Use direct node execution (NOT "npm start") for better signal handling
# The path dist/server/entry.mjs is standard for @astrojs/node adapter
# If this path is wrong after building, check dist/ folder structure
CMD ["node", "./dist/server/entry.mjs"]