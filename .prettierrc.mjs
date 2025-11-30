/** @type {import("prettier").Config} */
export default {
  // Require semicolons at the end of statements
  semi: true,
  // Number of spaces per indentation level
  tabWidth: 2,
  // Maximum line length before Prettier wraps code (80 characters)
  printWidth: 80,
  // Use double quotes instead of single quotes
  singleQuote: false,
  // Add trailing commas where valid in ES5 (objects, arrays, etc.)
  trailingComma: "es5",
  // Print spaces between brackets in object literals: { foo: bar } vs {foo: bar}
  bracketSpacing: true,
  // Put > of opening tags on the last line instead of on a new line
  bracketSameLine: true,
  // Ignore whitespace sensitivity in HTML - more aggressive formatting
  htmlWhitespaceSensitivity: "ignore",
  // Always include parentheses around arrow function parameters: (x) => x
  arrowParens: "always",
  // Enable the Astro plugin to format .astro files
  plugins: ["prettier-plugin-astro"],
  // File-specific overrides - these options apply only to matching files
  overrides: [
    {
      // Apply these options only to .astro files
      files: "*.astro",
      options: {
        // Use the Astro parser to understand Astro syntax
        parser: "astro",
        // Keep closing > on same line as last attribute (redundant with root, but explicit for Astro)
        bracketSameLine: true,
        // Ignore HTML whitespace sensitivity (redundant with root, but explicit for Astro)
        htmlWhitespaceSensitivity: "ignore",
        // Don't force each attribute on its own line - allows attributes on same line when possible
        singleAttributePerLine: false,
      },
    },
  ],
};
