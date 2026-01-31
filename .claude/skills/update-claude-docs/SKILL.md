---
name: update-claude-docs
description: Update CLAUDE.md files across the project with context from recent branch changes. Run after making changes to keep documentation in sync with code.
---

This skill updates all CLAUDE.md files in the project to reflect recent code changes. It compares the current branch against main, analyzes what changed, and ensures documentation stays current with the project's logic and structure.

## When to Use

Run this skill after making significant changes to your branch, such as:

- Adding new components, pages, or features
- Changing project structure or architecture
- Adding new dependencies or configuration
- Modifying API routes or data flow
- Creating new directories or organizational patterns

## Workflow

### Step 1: Gather Context (Run Automatically)

**IMPORTANT:** Start by running these commands to gather all necessary context:

```bash
echo "=== CLAUDE.md FILES IN PROJECT ==="
find . -name "CLAUDE.md" -type f 2>/dev/null

echo ""
echo "=== CURRENT BRANCH ==="
git branch --show-current

echo ""
echo "=== CHANGED FILES (vs main) ==="
git diff main...HEAD --name-only 2>/dev/null || echo "No main branch or no changes"

echo ""
echo "=== CHANGE SUMMARY ==="
git diff main...HEAD --stat 2>/dev/null || echo "No main branch or no changes"

echo ""
echo "=== RECENT COMMITS ==="
git log main..HEAD --oneline 2>/dev/null || git log -10 --oneline

echo ""
echo "=== NEW/MODIFIED DIRECTORIES ==="
git diff main...HEAD --name-only 2>/dev/null | xargs -I {} dirname {} | sort -u | head -20
```

### Step 2: Analyze the Output

From the gathered context, identify:

- **All CLAUDE.md files** that exist in the project
- **Changed files** grouped by directory/feature area
- **New directories** that may need documentation
- **Key changes** affecting components, configs, or dependencies

Focus on changes that affect:

- **Project structure** - New directories, moved files, renamed components
- **Architecture** - New patterns, data flow changes, state management
- **Components** - New components, component organization, shared utilities
- **Configuration** - New env vars, build config, dependencies
- **API/Routes** - New endpoints, changed request/response patterns

### Step 3: Categorize Changes by Scope

Determine which CLAUDE.md file(s) should be updated:

| Change Type               | Update Target                                 |
| ------------------------- | --------------------------------------------- |
| New top-level directories | Root `CLAUDE.md`                              |
| New dependencies/config   | Root `CLAUDE.md`                              |
| New component patterns    | Root `CLAUDE.md` or component-specific        |
| Feature-specific logic    | Feature-scoped `CLAUDE.md` (create if needed) |
| Page-specific patterns    | Page-scoped `CLAUDE.md` (create if needed)    |

### Step 4: Update Documentation

For each relevant CLAUDE.md file, update these sections as needed:

**Root CLAUDE.md typically includes:**

- Commands (build, dev, test, lint)
- Architecture overview
- Project structure with file/directory descriptions
- Key configuration and environment variables
- Important patterns and conventions

**Scoped CLAUDE.md files (feature/page-specific) include:**

- Purpose and responsibility of that area
- Key files and their roles
- Data flow and state management
- Dependencies on other parts of the codebase
- Testing approach for that area

### Step 5: Validate Updates

After updating, verify completeness:

```bash
# Ensure all CLAUDE.md files are tracked
grep -rl "CLAUDE.md" . --include="*.md" 2>/dev/null | wc -l

# Check git status for modified docs
git status | grep CLAUDE

# Review the diff of documentation changes
git diff --name-only | grep -i claude
```

## Guidelines for Updates

**DO:**

- Keep descriptions concise and scannable
- Use consistent formatting (headers, bullet points, code blocks)
- Document the "why" not just the "what"
- Include file paths when referencing code
- Update project structure sections when adding directories
- Add new environment variables to the list
- Document new component patterns or conventions

**DON'T:**

- Add implementation details that belong in code comments
- Duplicate information already in README.md
- Include temporary or WIP notes
- Add verbose explanations - keep it reference-style
- Forget to remove documentation for deleted features

## Creating New Scoped CLAUDE.md Files

When a feature or area becomes complex enough to warrant its own context:

1. Create the file at the appropriate level (e.g., `src/features/auth/CLAUDE.md`)
2. Add a reference to it in the root CLAUDE.md project structure section
3. Include:
   - Brief purpose statement
   - Key files and their responsibilities
   - Important patterns specific to that area
   - Any gotchas or non-obvious behavior

Example structure for a scoped CLAUDE.md:

```markdown
# Feature Name

Brief description of what this feature does.

## Key Files

- `Component.astro` - Main entry point
- `utils.ts` - Helper functions for X
- `types.ts` - TypeScript interfaces

## Patterns

- Uses X pattern for Y reason
- Data flows from A → B → C

## Dependencies

- Relies on `@/components/shared/Button`
- Requires `FEATURE_API_KEY` env var
```

## Checklist Before Completing

- [ ] All CLAUDE.md files found via grep are reviewed
- [ ] Project structure section reflects current directories
- [ ] New components/features are documented
- [ ] Removed features are cleaned from docs
- [ ] New environment variables are listed
- [ ] New dependencies affecting architecture are noted
- [ ] File paths in docs are accurate and up-to-date
