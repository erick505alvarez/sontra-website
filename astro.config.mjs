// Enable TypeScript type checking in this JavaScript file
// @ts-check
// Import Astro's configuration helper function
import { defineConfig } from "astro/config";
// Import Node.js adapter for server-side rendering and API routes
import node from "@astrojs/node";

// Import Tailwind CSS Vite plugin for Tailwind v4 integration
import tailwindcss from "@tailwindcss/vite";

// https://astro.build/config
// Export the Astro configuration object
export default defineConfig({
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
    plugins: [tailwindcss()],
  },
});
