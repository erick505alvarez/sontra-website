// astro.config.mjs

// Enable TypeScript type checking in this JavaScript file
// @ts-check
// Import Astro's configuration helper function
import { defineConfig, envField } from "astro/config";
// Import Node.js adapter for server-side rendering and API routes
import node from "@astrojs/node";
// Import Tailwind CSS Vite plugin for Tailwind v4 integration
import tailwindcss from "@tailwindcss/vite";

const isDev = process.env.NODE_ENV === "development";

// https://astro.build/config
// Export the Astro configuration object
export default defineConfig({
  site: isDev ? "localhost:4321" : "https://sontra.dev",
  // configure schema for env variable
  env: {
    schema: {
      RESEND_API_KEY: envField.string({
        context: "server",
        access: "secret",
        optional: false,
      }),
      RESEND_EMAIL_DOMAIN: envField.string({
        context: "server",
        access: "secret",
        optional: false,
      }),
      TARGET_INBOX: envField.string({
        context: "server",
        access: "secret",
        optional: false,
      }),
    },
  },
  // Add this server configuration
  server: {
    host: true, // This tells Astro to listen on 0.0.0.0
    port: 4321,
  },
  // Configure output mode for server-side rendering
  // This enables API routes and dynamic rendering
  output: "server",
  // Add Node.js adapter for self-hosting on DigitalOcean
  adapter: node({
    mode: "standalone", // Runs as a standalone Node.js server
  }),
  // Vite configuration - Astro uses Vite under the hood
  vite: {
    // Add Tailwind CSS plugin to Vite's plugin array
    // This enables Tailwind CSS processing during build and dev
    // @ts-ignore - Vite version mismatch between Astro and Tailwind plugin
    plugins: [tailwindcss()],
  },
});
