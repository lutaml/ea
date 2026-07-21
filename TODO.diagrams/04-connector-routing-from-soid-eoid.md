# 04 - Connector Routing via SOID/EOID Resolution

## Status: DONE (2026-07-21, folded into TODO 03)

## Problem

EA connector geometry stores only bend deltas (SX/SY/EX/EY) and
the EDGE code (which side of the element the line attaches to).
The actual line endpoints are computed by EA's renderer at draw
time, by looking up the source and target element placements via
their DUIDs (style `SOID` and `EOID`).

Our current QEA adapter computes waypoints from the connector's
Start_Object_ID/End_Object_ID via the model. That works but
ignores the EDGE hint, producing lines that always start at the
element center instead of the correct edge.

## Approach

In both the QEA and XMI source adapters, when building a
DiagramConnector:

1. Resolve source and target placements via SOID/EOID (XMI) or
   Start_Object_ID/End_Object_ID (QEA).
2. Read the `EDGE` field (1=top, 2=right, 3=bottom, 4=left,
   5..8 = diagonal variants).
3. Compute the source connection point as the center of the
   chosen edge on the source element.
4. Apply the SX/SY delta to get the first bend.
5. Apply the EX/EY delta from the target edge center to get the
   second bend.
6. Compute the target connection point as the center of the
   chosen edge on the target element.

Emit exactly 2-4 waypoints: source edge → first bend → second
bend → target edge. This matches EA's typical "L" or "Z" routing.

For connectors without EDGE or SOID/EOID, fall back to straight
line between element centers.

## Files

- `lib/ea/sources/qea/diagram_builder.rb`
- `lib/ea/sources/xmi/diagram_builder.rb`
- `lib/ea/svg/edge_anchor.rb` (computes edge center given bounds +
  EDGE code)
- `spec/ea/svg/edge_anchor_spec.rb`

## Verification

- Spec: source element with EDGE=1 produces a source point at the
  top edge center.
- Spec: connector with both bends produces 4 waypoints.
- Visual: connector lines visually attach to element edges, not
  centers.
