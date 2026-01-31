# Industry Showcase Components

Interactive tabbed interface showcasing AI voice agent capabilities across 7 industries.

## Components

### Main Components

- **IndustryShowcase.astro** - Main wrapper with client-side JavaScript for tab switching and auto-rotation
- **IndustryTabs.astro** - Horizontal scrolling navigation with Lucide icons and progress indicator
- **IndustryTab.astro** - Individual tab button with ARIA attributes (accepts icon via named slot)

### Content Components

Each renders a 2-column layout (benefits left, industry-specific UI mockup right):

- **HomeServicesContent.astro** - Lead capture cards
- **EcommerceContent.astro** - Customer chat interface
- **HealthPracticesContent.astro** - Appointment calendar
- **AutomotiveDealershipsContent.astro** - After-hours chat
- **LegalServicesContent.astro** - Call transcript
- **RealEstateContent.astro** - Property listings
- **HospitalityContent.astro** - Guest inquiry

## Interactive Features

The IndustryShowcase uses client-side JavaScript (`<script>` block) for:

- **Tab switching** - Click tabs to change displayed content
- **Auto-rotation** - Cycles through tabs every 5 seconds
- **Pause on hover/focus** - Rotation pauses when user interacts
- **Keyboard navigation** - Arrow keys navigate between tabs
- **Progress indicator** - Visual bar shows time until next rotation
- **Intersection Observer** - Only rotates when section is visible

## Usage

```astro
---
import IndustryShowcase from "@components/landing/IndustryShowcase/IndustryShowcase.astro";
---

<IndustryShowcase activeIndustry="home-services" />
```

### Industry IDs

- `home-services`
- `ecommerce`
- `health-practices`
- `automotive-dealerships`
- `legal-services`
- `real-estate`
- `hospitality`

## Accessibility

Full ARIA support:

- `role="tablist"` on tab container
- `role="tab"` with `aria-selected` on each tab
- `role="tabpanel"` with `aria-labelledby` on content panels
- Focus ring on tabs, pause rotation during keyboard navigation

## Styling

Uses Tailwind CSS with project theme:

- `text-primary` - Brand color (#014e5a)
- `font-heading` - Sora font
- Animations defined in `global.css` (`fadeIn`, `progressBar`)

## Dependencies

- `@lucide/astro` - Icons used:
  - Tabs: `House`, `ShoppingCart`, `Stethoscope`, `Car`, `Scale`, `Building2`, `Hotel`
  - Content: `CheckCircle2`
- Tailwind CSS v4
