# 20 - Visibility Glyph Font (Plus Sign in Monospace)

## Status: DONE (2026-07-23)

## Outcome

Three text-encoding fixes:
1. Visibility marker now emits as `+ ` (with trailing space) —
   matches EA's text content exactly.
2. Namespace separator in type names converted to `::` (UML
   standard) — `gml:CodeType` → `gml::CodeType`.
3. Abstract class names no longer get double underscore when the
   source name already starts with `_` (e.g. `_Feature` stays
   `_Feature`, not `__Feature`).

## Remaining gap

Text counts overshoot ref on diagrams where the source classifier
has more `ownedAttribute` entries than EA displays. EA truncates the
visible attribute list (likely a per-diagram display filter or box-
size fit), while we render every property. This is a content-
filtering concern, not an encoding concern — deferred.

## Files changed

- `lib/ea/svg/ea_emitter/elements.rb` — `abstract_name`,
  `namespace_double_colon`, `split_visibility` updates
