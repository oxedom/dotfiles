---
name: react-best-practices
description: Client-side React performance optimization guidelines. This skill should be used when writing, reviewing, or refactoring React code to ensure optimal performance patterns. Triggers on tasks involving React components, hooks, data fetching, bundle optimization, or performance improvements.
license: MIT
metadata:
  version: "1.1.0"
---

# React Best Practices

Performance optimization guide for client-side React applications. Contains 56 rules across 7 categories, prioritized by impact to guide automated refactoring and code generation.

Adapted from [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices) with all Next.js- and server-rendering-specific guidance removed.

## When to Apply

Reference these guidelines when:
- Writing new React components or hooks
- Implementing client-side data fetching
- Reviewing code for performance issues
- Refactoring existing React code
- Optimizing bundle size or load times

## Out of Scope

This skill deliberately covers **client-side React only**. It contains no guidance on
React Server Components, server actions, SSR/hydration, framework routers, or any
Next.js-specific API. If a task genuinely needs those, say so rather than
extrapolating from these rules.

## Rule Categories by Priority

| Priority | Category | Impact | Prefix | Rules |
|----------|----------|--------|--------|-------|
| 1 | Eliminating Waterfalls | CRITICAL | `async-` | 5 |
| 2 | Bundle Size Optimization | CRITICAL | `bundle-` | 6 |
| 3 | Client-Side Data Fetching | MEDIUM-HIGH | `client-` | 4 |
| 4 | Re-render Optimization | MEDIUM | `rerender-` | 15 |
| 5 | Rendering Performance | MEDIUM | `rendering-` | 8 |
| 6 | JavaScript Performance | LOW-MEDIUM | `js-` | 14 |
| 7 | Advanced Patterns | LOW | `advanced-` | 4 |

## Quick Reference

### 1. Eliminating Waterfalls (CRITICAL)

- `async-cheap-condition-before-await` - Check cheap sync conditions before awaiting flags
- `async-defer-await` - Move await into branches where actually used
- `async-dependencies` - Use better-all for partial dependencies
- `async-parallel` - Use Promise.all() for independent operations
- `async-suspense-boundaries` - Use Suspense to stream content

### 2. Bundle Size Optimization (CRITICAL)

- `bundle-analyzable-paths` - Keep dynamic import paths statically analyzable
- `bundle-barrel-imports` - Import directly, avoid barrel files
- `bundle-conditional` - Load modules only when feature is activated
- `bundle-defer-third-party` - Load analytics/logging lazily after mount
- `bundle-dynamic-imports` - Use React.lazy() for heavy components
- `bundle-preload` - Preload on hover/focus for perceived speed

### 3. Client-Side Data Fetching (MEDIUM-HIGH)

- `client-event-listeners` - Deduplicate global event listeners
- `client-localstorage-schema` - Version and minimize localStorage data
- `client-passive-event-listeners` - Use passive listeners for scroll
- `client-swr-dedup` - Use SWR for automatic request deduplication

### 4. Re-render Optimization (MEDIUM)

- `rerender-defer-reads` - Don't subscribe to state only used in callbacks
- `rerender-dependencies` - Use primitive dependencies in effects
- `rerender-derived-state` - Subscribe to derived booleans, not raw values
- `rerender-derived-state-no-effect` - Derive state during render, not effects
- `rerender-functional-setstate` - Use functional setState for stable callbacks
- `rerender-lazy-state-init` - Pass function to useState for expensive values
- `rerender-memo` - Extract expensive work into memoized components
- `rerender-memo-with-default-value` - Hoist default non-primitive props
- `rerender-move-effect-to-event` - Put interaction logic in event handlers
- `rerender-no-inline-components` - Don't define components inside components
- `rerender-simple-expression-in-memo` - Avoid useMemo for simple primitives
- `rerender-split-combined-hooks` - Split hooks with independent dependencies
- `rerender-transitions` - Use startTransition for non-urgent updates
- `rerender-use-deferred-value` - Defer expensive renders to keep input responsive
- `rerender-use-ref-transient-values` - Use refs for transient frequent values

### 5. Rendering Performance (MEDIUM)

- `rendering-activity` - Use Activity component for show/hide
- `rendering-animate-svg-wrapper` - Animate div wrapper, not SVG element
- `rendering-conditional-render` - Use ternary, not && for conditionals
- `rendering-content-visibility` - Use content-visibility for long lists
- `rendering-hoist-jsx` - Extract static JSX outside components
- `rendering-script-defer-async` - Use defer or async on script tags
- `rendering-svg-precision` - Reduce SVG coordinate precision
- `rendering-usetransition-loading` - Prefer useTransition for loading state

### 6. JavaScript Performance (LOW-MEDIUM)

- `js-batch-dom-css` - Avoid layout thrashing; batch reads, then writes
- `js-cache-function-results` - Cache function results in module-level Map
- `js-cache-property-access` - Cache object properties in loops
- `js-cache-storage` - Cache localStorage/sessionStorage reads
- `js-combine-iterations` - Combine multiple filter/map into one loop
- `js-early-exit` - Return early from functions
- `js-flatmap-filter` - Use flatMap to map and filter in one pass
- `js-hoist-regexp` - Hoist RegExp creation outside loops
- `js-index-maps` - Build Map for repeated lookups
- `js-length-check-first` - Check array length before expensive comparison
- `js-min-max-loop` - Use loop for min/max instead of sort
- `js-request-idle-callback` - Defer non-critical work to browser idle time
- `js-set-map-lookups` - Use Set/Map for O(1) lookups
- `js-tosorted-immutable` - Use toSorted() for immutability

### 7. Advanced Patterns (LOW)

- `advanced-effect-event-deps` - Don't put `useEffectEvent` results in effect deps
- `advanced-event-handler-refs` - Store event handlers in refs
- `advanced-init-once` - Initialize app once per app load
- `advanced-use-latest` - useEffectEvent for stable callback refs

## How to Use

Read individual rule files for detailed explanations and code examples:

```
rules/async-parallel.md
rules/bundle-barrel-imports.md
```

Each rule file contains:
- Brief explanation of why it matters
- Incorrect code example with explanation
- Correct code example with explanation
- Additional context and references

## Full Compiled Document

For the complete guide with all rules expanded: `AGENTS.md`

Regenerate it after editing `rules/` with `python3 build.py` (or verify with
`python3 build.py --check`).
