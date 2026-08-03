# 37 - Package Shape Rendering (Polygon + Tab)

## Status: TODO (deferred — needs Package classifier model)

## Context

EA renders Package classifiers as a 5-point POLYGON with a tab.
Our model doesn't have a Package classifier type — packages are
modeled as a separate concept (Ea::Model::Package), not as
classifiers on diagrams.

To implement:
1. Detect when a DiagramElement references a Package (via
   model_element_ref → Ea::Model::Package)
2. New PackageShapeRenderer emits polygon-based shape
3. Elements#groups_for dispatches to PackageShapeRenderer for
   packages

## Decision

Deferred — needs investigation of how packages appear on
diagrams in the Ea::Model layer.
