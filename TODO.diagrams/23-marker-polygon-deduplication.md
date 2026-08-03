# TODO-D 23: Marker polygon deduplication rules

## Problem

EA's rules for emitting polygon markers when multiple connectors
share an endpoint are non-obvious.

## Empirical Observations

Aggregate across 188 reference SVGs:
- Total polygons: 1485
- Exact-duplicate polygons (same points string): **536** (36%)

EA duplicates polygon markers in many cases but not always. The
discriminator is unclear.

## Experiments Tried

| Strategy                    | Polygon delta | Within-tol |
|-----------------------------|---------------|------------|
| Anchor-based dedup (current)| -166 (-11.2%) | 123/188 (65.4%) |
| No dedup                    | +257 (+17.3%) | 139/188 (73.9%) |
| Exact-body dedup            | +247 (+16.6%) | 141/188 (75.0%) |

Both "no dedup" and "exact-body dedup" improve within-tolerance
diagram count (+13%) but introduce polygon overshoot. Anchor-based
dedup has best polygon delta but lower diagram-tol rate.

## Hypothesis To Test

EA likely has per-marker-per-connector emission for `Path=`-routed
connectors (each visible link emits its own markers) but deduplicates
markers that share an anchor AND belong to connectors sharing a
common segment.

The QEA stores a `Path=` field on t_diagramlinks; connectors that
share the same visual path are co-rendered. We currently treat
each t_diagramlinks row independently.

## Acceptance (when picked up)

- Correlate polygon duplicates with shared `Path=` values.
- Implement per-diagram `grouped:` mode selection in Markers.
- Specs cover: distinct anchors (no dedup), shared anchor + shared
  path (dedup), shared anchor + distinct path (no dedup).
- Polygon delta within ±20 (currently -166).
- Within-tolerance diagrams ≥ 75% (currently 65.4%).
