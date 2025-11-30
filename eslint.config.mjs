// Import the Astro ESLint plugin for Astro-specific linting rules
import eslintPluginAstro from "eslint-plugin-astro";
// Import the TypeScript parser to parse TypeScript syntax
import tsparser from "@typescript-eslint/parser";

// Export ESLint flat config array (ESLint 9+ format)
export default [
  // Spread Astro's recommended rule set - adds best practices for Astro files
  // This automatically handles .astro files with the correct parser
  ...eslintPluginAstro.configs.recommended,
  // Configuration for TypeScript files only (NOT .astro files)
  {
    // Apply this config only to TypeScript files
    // Note: .astro files are handled by eslint-plugin-astro above
    files: ["**/*.ts", "**/*.tsx"],
    languageOptions: {
      // Use TypeScript parser to understand TypeScript syntax
      parser: tsparser,
      parserOptions: {
        // Use the latest ECMAScript version
        ecmaVersion: "latest",
        // Code uses ES modules (import/export)
        sourceType: "module",
      },
    },
  },
  // Ignore files that don't need linting
  {
    ignores: [
      "**/*.json",
      "**/*.css",
      "**/*.scss",
      "**/*.md",
      "**/node_modules/**",
      "**/dist/**",
      "**/.astro/**",
    ],
  },
  // Global rules that apply to all files
  {
    rules: {
      // override/add rules settings here, such as:
      // "astro/no-set-html-directive": "error"
      "capitalized-comments": ["error", "always"],
    },
  },
];
