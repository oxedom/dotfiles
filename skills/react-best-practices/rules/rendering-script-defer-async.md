---
title: Use defer or async on Script Tags
impact: HIGH
impactDescription: eliminates render-blocking
tags: rendering, script, defer, async, performance
---

## Use defer or async on Script Tags

Script tags without `defer` or `async` block HTML parsing while the script downloads and executes. This delays First Contentful Paint and Time to Interactive.

- **`defer`**: Downloads in parallel, executes after HTML parsing completes, maintains execution order
- **`async`**: Downloads in parallel, executes immediately when ready, no guaranteed order

Use `defer` for scripts that depend on the DOM or on other scripts. Use `async` for independent scripts like analytics.

**Incorrect (blocks rendering):**

```html
<!-- index.html -->
<head>
  <script src="https://example.com/analytics.js"></script>
  <script src="/scripts/utils.js"></script>
</head>
```

**Correct (non-blocking):**

```html
<!-- index.html -->
<head>
  <!-- Independent script - use async -->
  <script src="https://example.com/analytics.js" async></script>
  <!-- DOM-dependent script - use defer -->
  <script src="/scripts/utils.js" defer></script>
</head>
```

Module scripts (`<script type="module">`) are deferred by default, so a bundler-generated entry point is already non-blocking. This rule matters most for hand-written third-party tags you add to the HTML shell.

For a script that is only needed once a particular feature is used, prefer not putting it in the HTML at all — load it on demand with a dynamic `import()`. See [Conditional Module Loading](./bundle-conditional.md).

Reference: [MDN - Script element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script#defer)
