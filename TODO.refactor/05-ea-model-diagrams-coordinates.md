# 05 - Diagrams with Coordinates (the EA value-add)

## Status: DONE (2026-07-19, folded into TODO 01)

## Problem

EA diagrams carry pixel-accurate element positions, connector
waypoints, color and font styling. UML-only SPAs drop all of this
and present a tree of classes. For browsing the original model,
the diagram IS the artifact.

## Approach

Modeled in TODO 01 as:

- `Ea::Model::Diagram` — owns elements + connectors + metadata
- `Ea::Model::DiagramElement` — `model_element_ref` (id to a
  Classifier/Package/etc.), `bounds` (x,y,w,h), `style` (parsed
  from EA's packed `Style` string into typed fields: fill, line,
  font, etc.)
- `Ea::Model::DiagramConnector` — `relationship_ref` (id to a
  Relationship), `waypoints` (ordered list of Points), `labels`,
  `style`
- `Ea::Model::Waypoint` — `Point` + optional routing hint
- `Ea::Model::Point` (x: Integer, y: Integer)
- `Ea::Model::Bounds` (x, y, width, height)

Style parsing lives in `Ea::Sources::Qea::DiagramStyleParser` —
takes the EA `styleex`/`Style` packed strings and emits a typed
`DiagramStyle` value. Same parser pattern as `Ea::Diagram::StyleParser`
(which exists today for the SVG renderer); we share or unify.

## Verification

- Spec: parse a real EA diagram from plateau model fixture, assert
  element bounds and connector waypoints are non-empty
- Spec: diagram projects to SPA shape with bounds/waypoints intact
