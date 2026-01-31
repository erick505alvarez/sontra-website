# Diff for Docs

Standalone command to gather git context. This is automatically run by `/update-claude-docs` skill, but can be used independently.

Run these commands:

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
