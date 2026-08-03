# 17 - Path Count Calibration

## Status: DONE (2026-07-25)

## Outcome

Removed navigability arrow emission from aggregations. EA's
diagrams do NOT render an arrow at the part end of aggregations
— the diamond already conveys direction.

Updated `Marker::Diamond` to emit only ONE spec (the diamond),
not two (diamond + arrow). Updated spec accordingly.

## Outcome metrics

Path count within ±2: 49% → 49% (no aggregate change since path
diffs come from other sources too).

Bridge: 140 → 127 paths (ref=113, was +27, now +14).
Building: 112 → 102 (ref=96, was +16, now +6).

Significant reduction on individual diagrams.

## Files changed

- `lib/ea/svg/ea_emitter/marker/diamond.rb` — single spec only
- `spec/ea/svg/ea_emitter/marker/registry_spec.rb` — updated expectation
