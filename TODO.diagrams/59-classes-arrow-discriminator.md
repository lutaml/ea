# TODO-D 59: Classes diagram association arrow discriminator

## Status: open (blocks 2 basic.qea diagrams)

Two basic.qea "Classes" diagrams have shape_delta=1 each. We render
one extra `<path>` per diagram — the navigability arrow at the
target end of an Association connector that EA's reference SVG
omits.

## Investigation summary

Compared fields across the rendering-pipeline:

| Diagram | Direction | SourceStyle | DestStyle | LineStyle | RouteStyle | SourceCard | DestCard | SourceIsAggregate | DestIsAggregate | SX/SY/EX/EY | Object types |
|---------|-----------|-------------|-----------|-----------|------------|------------|----------|-------------------|-----------------|-------------|--------------|
| Multiplicities (HAS arrow) | Unspecified | Navigable=U | Navigable=U | 0 | 3 | 0..* | 0..* | 0 | 0 | -6/-2/-57/-2 | Class ↔ Class |
| Classes (NO arrow) | Unspecified | Navigable=U | Navigable=U | 0 | 3 | 0..2 | 1 | 0 | 0 | -1/4/3/4 | Class ↔ Class |

All fields identical except cardinality and SX/SY/EX/EY values.
The visual difference: Multiplicities renders as a single straight
path + arrow polygon; Classes renders as 3 separate horizontal
segments + no arrow. EA appears to apply an internal "are bends
real?" heuristic.

## Hypothesis

EA computes the maximum perpendicular deviation of bend waypoints
from the straight source-target line. Below a threshold (likely
~2-3px), bends are treated as noise and the connector renders as
straight WITH navigability arrow. Above the threshold, the
connector renders as orthogonal segments with NO arrow.

For Multiplicities: deviations 1-2px → straight + arrow.
For Classes: deviations 4-5px → segmented + no arrow.

## Implementation plan

- In `Ea::Svg::EaEmitter::Connectors#path_for`, compute the
  perpendicular deviation of each interior waypoint from the
  source-target line. If max deviation ≤ THRESHOLD (try 3), emit
  a straight 2-point path. Otherwise keep current multi-segment
  path.
- In `Ea::Svg::EaEmitter::Markers#suppress_arrow?`, suppress
  Association arrow when the connector is multi-segment (max
  deviation > THRESHOLD).
- THRESHOLD constant lives on `Connectors` (or a shared
  `ConnectorRouting` module) so both renderers use the same value.

## Verification

- basic.qea "Classes" (×2): shape_delta 1 → 0.
- basic.qea: 16/22 → 18/22 strict-perfect.

## Risk

The threshold value is reverse-engineered from a single sample.
Verifying against plateau connectors would confirm.
