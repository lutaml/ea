# Frontend (Vue 3 SPA)

The `ea spa` command emits a single-page application built from this
directory. The dist artifacts are committed so the gem ships
pre-built and never needs `npm` at install time.

## Layout

```
frontend/
├── src/            # Vue 3 + Pinia source
├── dist/           # Built bundle (committed) — app.iife.js + style.css
├── tests/e2e/      # Vitest browser tests + reference screenshots
├── package.json    # npm manifest
├── vite.config.ts  # Build config (IIFE output, single chunk)
└── tsconfig.json   # TypeScript config
```

## When to rebuild

Any change to `src/`, `package.json`, or `vite.config.ts` requires a
rebuild. CI (`.github/workflows/frontend.yml`) fails the build if
`dist/` doesn't match a fresh build, so a stale bundle can't merge.

## Rebuild

```bash
cd frontend
npm install
npm run build      # → dist/app.iife.js, dist/style.css
```

The output is small (~134 KB total, 38 KB gzipped) and self-contained.
Both `lib/ea/spa/output/single_file_strategy.rb` (inlines the bundle
into the HTML) and `sharded_multi_file_strategy.rb` (copies the
bundle as `app.js` / `style.css` next to `index.html`) read from
`frontend/dist/` via `Ea::Spa::Output::Strategy::FRONTEND_DIST_DIR`.

## Data contract

The SPA expects the shell to set:

- `window.__SPA_DATA__` — single-file mode: a complete payload with
  `metadata`, `packageTree`, `skeletonEntries`, `searchIndex`, `shards`
- `window.__SPA_SKELETON_URL__`, `__SPA_SEARCH_URL__`,
  `__SPA_SHARD_BASE__` — sharded mode: URLs the SPA fetches lazily

The sharded loader fetches `${__SPA_SHARD_BASE__}${plural}/${id}.json`
on demand; for a class with id `c1`, the SPA fetches
`data/classes/c1.json`. Shard files have the shape
`{ "id": ..., "kind": "class"|"package"|"enumeration"|..., "payload": {...} }`.
