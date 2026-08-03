# 20 - Stereotype Color from Classifier (Beyond BCol)

## Status: DONE (2026-07-25)

## Outcome

`Element::BColDecoder` now treats `-1` as a sentinel meaning "no
color override" and returns nil. `Elements#groups_for` falls
through to `fill_for_classifier` which consults the
`StereotypeColorResolver` for the classifier's stereotype.

Effect: elements with `BCol=-1` (sentinel) now pick up the
canonical color for their stereotype (e.g., yellow for
«FeatureType»).

## Files changed

- `lib/ea/svg/ea_emitter/element/bcol_decoder.rb` — SENTINEL constant
