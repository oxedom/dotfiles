---
title: Prefer Statically Analyzable Paths
impact: HIGH
impactDescription: avoids accidental broad bundles
tags: bundle, vite, webpack, rollup, esbuild, path, dynamic-import
---

## Prefer Statically Analyzable Paths

Bundlers work best when import paths are obvious at build time. If you hide the real path inside a variable or compose it too dynamically, the bundler either has to include every file that could possibly match, or warns that it cannot analyze the import at all.

Prefer an explicit map of import thunks so the set of reachable modules stays narrow and predictable.

When analysis becomes too broad, the cost is real:
- Larger bundles and more chunks than you intended
- Slower builds
- Worse cold starts on first navigation

**Incorrect (the bundler cannot tell what may be imported):**

```ts
const PAGE_MODULES = {
  home: './pages/home',
  settings: './pages/settings',
} as const

const Page = await import(PAGE_MODULES[pageName])
```

The bundler sees `import(someVariable)`. Depending on the tool it will either bundle every module under `./pages/`, emit an "unanalyzable dynamic import" warning, or fail outright.

**Correct (use an explicit map of allowed modules):**

```ts
const PAGE_MODULES = {
  home: () => import('./pages/home'),
  settings: () => import('./pages/settings'),
} as const

const Page = await PAGE_MODULES[pageName]()
```

Each `import()` now has a literal specifier, so exactly two chunks are emitted and the map stays type-safe.

The same rule applies to any path a build tool needs to resolve statically: make the final value literal at the callsite rather than assembling it from variables.

Reference: [Vite features](https://vite.dev/guide/features.html), [Rollup dynamic import vars](https://www.npmjs.com/package/@rollup/plugin-dynamic-import-vars), [esbuild API](https://esbuild.github.io/api/), [Webpack dependency management](https://webpack.js.org/guides/dependency-management/)
