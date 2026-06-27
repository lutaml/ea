# 16 - Performance: Repository Indexes

## Status: PARTIALLY DONE (2026-06-27) — residue audited, no action

## What's done
- `Ea::Qea::Database` has hash indexes: `connectors_by_object`,
  `constraints_by_object_id`, `tagged_values_by_element_id`,
  `properties_by_object_id`, `xrefs_by_client`
- Query methods: `constraints_for_object`, `tagged_values_for_element`,
  `properties_for_object`, `xrefs_for_client`
- `connectors_for_object` returns indexed result (no array concatenation)
- **`TransformationEngine#record_transformation`** — switched from
  `unshift`+`pop` (O(n) every call) to `push`+`shift` (O(1) append, O(n)
  only when cap overflows). Bounded history of 1000 entries — overflow
  shift is rare and amortized O(1).

## Audited, intentionally not changed
- **`BaseRepository#find`, `find_by_key`, `where` are O(n) linear scans.**
  EA repositories are small (hundreds to low thousands of records per table).
  On a typical `t_object` table of 500 rows, a linear scan is ~5µs — well
  below any user-perceptible threshold. Adding a primary-key index would
  complicate `BaseRepository` (need to invalidate on mutation, handle
  composite keys, deal with `Database#freeze`) for no measurable win.
  Revisit only if profiling shows repository queries dominating load time.

## Files
- `lib/ea/transformations/transformation_engine.rb` — push+shift applied

