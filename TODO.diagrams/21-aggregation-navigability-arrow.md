# 21 - Aggregation Navigability Arrow at Part End

## Status: DONE (2026-07-23)

## Outcome

`Markers#marker_specs` for Aggregation/Composition now returns TWO
Specs:
- Diamond polygon at whole end
- Arrow path at part end

Document interleaves line + diamond + arrow per aggregation
connector (via `count_for` API + `pair_per_connector`).

Waterway path count: 15 → 21 (ref=20, within ±1).
Bridge polygon+path counts now within ±2 of ref.

## Files changed

- `lib/ea/svg/ea_emitter/markers.rb` — `marker_specs` returns Array, `count_for` API
- `lib/ea/svg/ea_emitter/document.rb` — `pair_per_connector` interleave
