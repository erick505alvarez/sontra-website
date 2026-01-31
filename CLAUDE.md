# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev      # Start dev server at localhost:4321
npm run build    # Build for production to ./dist/
npm run start    # Run production build (after build)
npm run preview  # Preview production build locally
npm run lint     # Run ESLint on .astro, .js, .jsx, .ts, .tsx files
```

## Architecture

This is an Astro website for sontra.dev with server-side rendering (SSR) deployed to a Node.js server.

### Key Configuration

- **Output mode**: Server-side rendered (`output: "server"` in astro.config.mjs)
- **Adapter**: `@astrojs/node` in standalone mode for self-hosting
- **Styling**: Tailwind CSS v4 via Vite plugin (not the Astro integration)
- **Email**: Resend API for contact form submissions

### Path Aliases

Defined in tsconfig.json:

- `@/*` → `./src/*`
- `@components/*` → `./src/components/*`
- `@images/*` → `./src/images/*`

### Project Structure

- `src/pages/` - File-based routing (index.astro, booking.astro, 404.astro)
- `src/pages/api/` - API routes (contact.ts handles form submissions)
- `src/components/` - Astro components
- `src/layouts/` - BaseLayout.astro wraps all pages
- `src/styles/global.css` - Tailwind imports and theme customization
- `src/middleware.ts` - Rate limiting middleware (100 req/min per IP)
- `src/types/` - TypeScript interfaces

### Environment Variables

Required server-side secrets (defined in astro.config.mjs env schema):

- `RESEND_API_KEY`
- `RESEND_EMAIL_DOMAIN`
- `TARGET_INBOX`

### Linting Rules

- ESLint uses flat config (eslint.config.mjs)
- Comments must be capitalized (`"capitalized-comments": ["error", "always"]`)
- Pre-commit hooks run Prettier and ESLint via lint-staged
