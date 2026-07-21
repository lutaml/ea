# 01 - Reverse-Engineer EA's Connector Routing Algorithm

## Status: INVESTIGATING

## Problem

Our `Ea::Svg::EaEmitter::Connectors` produces paths that don't
visually connect the right element edges. Looking at one sample:

EA reference path: `M 294 136 L 294 181 L 521 181` — L-shaped
connector from bottom of source to left of target with one bend.

Our path: `M 183 410 → 166 410 → 124 241 → 145 201` — 4-point
polyline that doesn't visually connect anything.

The source XMI for connectors stores:
- `geometry="SX=5;SY=55;EX=5;EY=50;EDGE=4;..."` (bend deltas +
  edge code)
- `style="SOID=...;EOID=...;..."` (source/target DUIDs)

Our current math (in Xmi::DiagramBuilder#compute_waypoints) is
wrong: it computes edge centers incorrectly and ignores the SX/SY
delta semantics.

## Approach

Studying EA's reference SVGs (192 of them in
mn-samples-plateau/sources/001-mds/xmi-images/) against the
source XMI, derive the EXACT algorithm EA uses to compute:

1. Source attachment point (which edge, what offset along edge)
2. Target attachment point
3. Bend points (if any)
4. Arrowhead orientation

The algorithm should produce a 2- or 3-point polyline (rarely 4)
matching EA's path data byte-for-byte for the same input.

## Files

- `lib/ea/svg/connector_router.rb` (new — pure routing math)
- `spec/ea/svg/connector_router_spec.rb`
- `spec/ea/svg/connector_routing_parity_spec.rb` — tests against
  N diagrams with EA reference SVGs; asserts path coords match
