# React Best Practices

A structured repository for creating and maintaining React Best Practices optimized for agents and LLMs.

Adapted from [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices).
This fork covers **client-side React only** — Next.js-specific rules (`server-*`,
`async-api-routes`), SSR/hydration rules (`rendering-hydration-*`,
`rendering-resource-hints`), and framework-specific examples have been removed or
rewritten framework-neutral.

## Structure

- `rules/` - Individual rule files (one per rule)
  - `_sections.md` - Section metadata (titles, impacts, descriptions)
  - `_template.md` - Template for creating new rules
  - `area-description.md` - Individual rule files
- `build.py` - Compiles `rules/` into `AGENTS.md`
- `metadata.json` - Document metadata (version, date, abstract, references)
- `SKILL.md` - Skill entry point (quick reference index)
- __`AGENTS.md`__ - Compiled output (generated)

## Getting Started

Build AGENTS.md from rules (no dependencies beyond Python 3):

```bash
python3 build.py
```

Verify AGENTS.md is in sync with `rules/`:

```bash
python3 build.py --check
```

## Creating a New Rule

1. Copy `rules/_template.md` to `rules/area-description.md`
2. Choose the appropriate area prefix:
   - `async-` for Eliminating Waterfalls (Section 1)
   - `bundle-` for Bundle Size Optimization (Section 2)
   - `client-` for Client-Side Data Fetching (Section 3)
   - `rerender-` for Re-render Optimization (Section 4)
   - `rendering-` for Rendering Performance (Section 5)
   - `js-` for JavaScript Performance (Section 6)
   - `advanced-` for Advanced Patterns (Section 7)
3. Fill in the frontmatter and content
4. Ensure you have clear examples with explanations
5. Run `python3 build.py` to regenerate AGENTS.md

## Rule File Structure

Each rule file should follow this structure:

```markdown
---
title: Rule Title Here
impact: MEDIUM
impactDescription: Optional description
tags: tag1, tag2, tag3
---

## Rule Title Here

Brief explanation of the rule and why it matters.

**Incorrect (description of what's wrong):**

```typescript
// Bad code example
```

**Correct (description of what's right):**

```typescript
// Good code example
```

Optional explanatory text after examples.

Reference: [Link](https://example.com)

## File Naming Convention

- Files starting with `_` are special (excluded from build)
- Rule files: `area-description.md` (e.g., `async-parallel.md`)
- Section is automatically inferred from filename prefix
- Rules are sorted alphabetically by title within each section
- IDs (e.g., 1.1, 1.2) are auto-generated during build

## Impact Levels

- `CRITICAL` - Highest priority, major performance gains
- `HIGH` - Significant performance improvements
- `MEDIUM-HIGH` - Moderate-high gains
- `MEDIUM` - Moderate performance improvements
- `LOW-MEDIUM` - Low-medium gains
- `LOW` - Incremental improvements

## Scripts

- `python3 build.py` - Compile rules into AGENTS.md
- `python3 build.py --check` - Fail if AGENTS.md is out of date

## Contributing

When adding or modifying rules:

1. Use the correct filename prefix for your section
2. Follow the `_template.md` structure
3. Include clear bad/good examples with explanations
4. Add appropriate tags
5. Run `python3 build.py` to regenerate AGENTS.md
6. Rules are automatically sorted by title - no need to manage numbers!

## Acknowledgments

Originally created by [@shuding](https://x.com/shuding).
