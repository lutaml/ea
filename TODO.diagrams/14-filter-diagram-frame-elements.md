# 14 - Filter Diagram-Frame / Note Elements

## Status: DONE (2026-07-23)

## Outcome

Added `Elements#frame_element?` predicate that skips elements
matching the diagram-frame pattern:
- `background_color == -1` (sentinel for "no fill / default"), AND
- Classifier name is nil/empty, AND
- Classifier has no properties

Verified: Waterway top-level `<g>` count drops 50→47, rect count
drops 10→9 — both now match EA reference exactly.

## Files changed

- `lib/ea/svg/ea_emitter/elements.rb` — `frame_element?` predicate
