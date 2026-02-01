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
- **Icons**: Lucide Astro (`@lucide/astro`) for UI icons
- **Email**: Resend API for contact form submissions

### Theme Colors

Defined in `src/styles/global.css` under `@theme`:

- `--color-primary: #014e5a` (teal) - Primary brand color, main CTAs, headers
- `--color-accent: #ea580c` (orange) - Secondary highlights, hover states, urgency indicators
- `--font-heading: "Sora"` - Headings
- `--font-body: "Inter"` - Body text

### Path Aliases

Defined in tsconfig.json:

- `@/*` → `./src/*`
- `@components/*` → `./src/components/*`
- `@images/*` → `./src/images/*`

### Project Structure

- `src/pages/` - File-based routing (index.astro, services.astro, booking.astro, 404.astro)
- `src/pages/api/` - API routes
  - `contact.ts` - Contact form submissions via Resend
  - `demo-call.ts` - Demo call requests forwarded to n8n webhook (includes bot detection)
- `src/components/` - Astro components
  - `src/components/landing-page/` - Landing page section components
    - `index.astro` - Barrel file composing all landing sections
    - `Hero.astro`, `SocialProof.astro`, `TestForm.astro`, `VideoSection.astro`, `ROICalculator.astro`, `ValueProp.astro`, `CaseStudy.astro`, `Calendar.astro`, `FAQs.astro`, `Integrations.astro`, `CallToAction.astro`
    - `IndustryShowcase/` - Interactive tabbed industry showcase with auto-rotation (see `CLAUDE.md` in that directory)
  - `src/components/services/` - Services page components (Hero, ProjectCard, ProjectsGrid, Testimonials)
- `src/layouts/` - BaseLayout.astro wraps all pages
- `src/styles/global.css` - Tailwind imports and theme customization
- `src/middleware.ts` - Rate limiting middleware (100 req/min per IP)
- `src/types/` - TypeScript interfaces
- `src/lib/utils.ts` - Utility functions (e.g., `cn()` for classname merging)

### Environment Variables

Required server-side secrets (defined in astro.config.mjs env schema):

- `RESEND_API_KEY` - Resend API key for email sending
- `RESEND_EMAIL_DOMAIN` - Domain for Resend emails
- `TARGET_INBOX` - Email address for contact form submissions
- `N8N_DEMO_CALL_WEBHOOK` - n8n webhook URL for demo call requests

### Linting Rules

- ESLint uses flat config (eslint.config.mjs)
- Comments must be capitalized (`"capitalized-comments": ["error", "always"]`)
- Pre-commit hooks run Prettier and ESLint via lint-staged
