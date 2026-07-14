---
name: sticky-action-bar
description: Use when building a pinned bottom action bar (submit, next, mark-complete, navigate) that stays docked to the viewport while users scroll long content — common in lessons, challenges, forms, and multi-step wizards. Trigger on phrases like "sticky bar", "docked footer", "floating submit", "pinned action bar", or when primary actions risk being scrolled out of view.
---

# Sticky Action Bar

## Overview

A **sticky action bar** is a horizontal strip of primary actions (Submit, Next, Clear, Continue) anchored to the bottom of the viewport via `position: sticky; bottom: 0`. As the user scrolls through long content, the bar remains visible. When the user scrolls past the bar's containing block, the bar scrolls away with it — unlike `position: fixed`, which would remain glued to the viewport forever.

**Core principle:** `position: sticky` behaves like `relative` until the element's containing block scrolls past a threshold (`bottom: 0`), at which point it pins. This keeps the bar scoped to its section, not the whole app.

## When to Use

- Primary call-to-action on a scrollable page (Submit, Next lesson, Mark complete)
- Long forms where the Submit button would otherwise require scrolling
- Challenge/assessment UIs where the Submit/Clear buttons must stay reachable
- Multi-step wizards where Back/Next should always be one click away

## When NOT to Use

- Short pages that fit in the viewport (no scroll = no need)
- Modals/dialogs with their own internal scroll and footer
- Secondary or tertiary actions (sticky bars are scarce real estate — use for the ONE main action per screen)
- Mobile-first designs where a fixed `bottom: env(safe-area-inset-bottom)` bar is more appropriate

## The Gotcha (read this first)

**`position: sticky` is silently broken by any ancestor with `overflow: hidden`, `overflow: auto`, or `overflow: scroll`.** This is the #1 reason sticky "doesn't work."

If an ancestor has `overflow-hidden` (common on cards with `rounded-lg overflow-hidden` to clip rounded corners), the sticky element's scroll container becomes that ancestor instead of the viewport. The bar will never pin.

**Fix:** Either remove `overflow-hidden` from the ancestor, or lift the sticky bar out of the clipping container as a sibling.

## Core Pattern

```tsx
<div className="page-container">
  {/* long scrollable content */}
  <ScenarioCard />
  <FragmentPool />
  <AssemblyZone />

  {/* sticky action bar — sibling of scrolling content, NOT nested in an overflow-hidden ancestor */}
  <div
    className="sticky bottom-0 z-40 mt-3 flex items-center justify-between
               rounded-lg border px-5 py-3 shadow-sm
               backdrop-blur supports-[backdrop-filter]:bg-white/85"
    style={{ background: "hsla(36, 30%, 97%, 0.95)" }}
  >
    <div>{/* status/summary text */}</div>
    <div className="flex gap-2">
      <Button variant="outline" onClick={onClear}>Clear</Button>
      <Button onClick={onSubmit}>Submit</Button>
    </div>
  </div>
</div>
```

**Key classes:**
- `sticky bottom-0` — the pin
- `z-40` (or `z-50`) — stack above scrolling content
- `backdrop-blur supports-[backdrop-filter]:bg-white/85` — translucent glass effect so content scrolling under is subtly visible
- `border-t` or full `border` + `rounded-lg` — visual separation from content above
- `mt-3` or `mt-8` — breathing room before the bar

## Variant: Full-Width Breakout Bar

When the bar should visually span edge-to-edge of the parent container (not just the inner content width), use negative margins to cancel the parent's padding:

```tsx
{/* parent has p-6 or px-6 */}
<div className="sticky bottom-0 z-50 -mx-6 px-6 border-t
                bg-background/95 backdrop-blur
                supports-[backdrop-filter]:bg-background/60">
  <div className="flex justify-center gap-3 py-3">
    <Button>View Catalog</Button>
    <Button>Mark Complete</Button>
    <Button>Next Lesson</Button>
  </div>
</div>
```

The `-mx-6 px-6` trick extends the bar to the parent's edges while keeping inner content aligned with the main column. Match the offset to the parent's horizontal padding.

## Quick Reference

| Need | Classes |
|------|---------|
| Basic sticky bar | `sticky bottom-0 z-40` |
| Translucent glass | `backdrop-blur supports-[backdrop-filter]:bg-white/85` |
| Full-width breakout | `-mx-6 px-6` (match parent padding) |
| Top border separator | `border-t` |
| Contained card look | `rounded-lg border shadow-sm` |
| Mobile safe area | `pb-[env(safe-area-inset-bottom)]` |

## Implementation Checklist

1. **Audit ancestors for `overflow-hidden`.** Walk up the DOM from the bar to the body. Any non-`visible` overflow on the scroll axis breaks sticky. Fix or reparent.
2. **Pick a scoping container.** The bar pins while its containing block is on screen. Place it as a sibling of the long content, inside whatever section should "own" the bar.
3. **Layer correctly.** `z-40`–`z-50`. Check for other `z-*` elements (modals, dropdowns, sidebars) that must still render above.
4. **Translucent or solid?** Use `backdrop-blur + bg-*/85` for the glass look (preferred on content-heavy pages). Use solid `bg-background` if content underneath is visually noisy.
5. **Respect reduced motion / safe areas.** On mobile PWAs, add `pb-[env(safe-area-inset-bottom)]` so iOS home-indicator doesn't overlap buttons.
6. **Test scroll behavior.** Scroll up: bar pinned. Scroll past the container: bar scrolls away. Confirm both.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Bar never pins | An ancestor has `overflow-hidden` or `overflow-auto`. Find it and remove, or move the bar out of that ancestor. |
| Bar pins but content scrolls over it | Missing or too-low `z-index`. Use `z-40`+. |
| Bar ignores parent padding (looks inset) | Add `-mx-N px-N` matching the parent's padding to break out edge-to-edge. |
| Bar overlaps the last content row | Add `mt-*` on the bar OR `pb-*` on the scroll container so the last row isn't hidden under the bar on initial render. |
| Bar stays forever (like fixed) | You're looking for `fixed`, not `sticky`. Sticky always releases when the containing block exits. |
| Bar renders behind iOS home indicator | Add `pb-[env(safe-area-inset-bottom)]`. |

## Real Examples in This Codebase (brinked.ai)

- `packages/client/src/routes/lessons/$slug.lazy.tsx` — lesson page navigation bar (View Catalog / Mark Complete / Next Lesson). Uses the **full-width breakout** variant with `-mx-6 px-6`.
- `packages/client/src/components/challenge/ParsonsEngine.tsx` — Parsons challenge Submit/Clear bar. Uses the **contained card** variant with `rounded-lg border`. Required closing the wrapping `<section>` early because it had `overflow-hidden` for rounded-corner clipping.

Reference these when porting the pattern to new pages — copy the variant that matches your layout, then audit ancestors for overflow traps.

## One-Sentence Summary

`position: sticky; bottom: 0; z-40` on a sibling of the scrolling content, with no `overflow-*` ancestor between them.
