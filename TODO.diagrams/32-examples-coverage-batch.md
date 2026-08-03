# TODO-D 32-35: Examples coverage batch

## Motivation

The user asked to test ALL of examples/ against QEAs, XMIs (model.xml),
and reference SVGs. Running through each fixture surfaced four bugs
that the plateau-only regression harness missed.

## Completed

### 32. Examples regression spec

`spec/ea/svg/examples_regression_spec.rb` runs each QEA, parses its
matching `model.xml`, and renders every diagram with a reference SVG.
Threshold is 0.4 average text-overlap (loose — known per-example gaps
documented in TODO.diagrams/).

Covers: plateau (188 diagrams), arcgis (6), basic (22), simple (2),
test (2) = **220 diagrams across 5 fixtures**.

### 33. Package label rendering

`PackageShapeRenderer` took a `label:` argument but never emitted it
as `<text>` — Package model elements had no visible name in the SVG.
Now renders the label inside the tab area, bold, using the same
font family/size as the element renderer.

Plateau impact: text delta -96 → -52 (44 package names recovered).
Simple impact: text delta -10 → -5.

### 34. Suppress implicit connectors

EA encodes package nesting as `Connector_Type = "Nesting"` rows in
`t_diagramlinks` but does NOT render them as paths in SVG — the
containment is implied by visual position.

Added `Ea::Model::DiagramConnector#renderable?` returning false for
hidden + implicit-type connectors. All three emitters (Connectors,
Markers, Labels) use the shared predicate instead of duplicating
the reject logic.

Simple example went from 6 paths (canvas + 5 nesting lines) to 1
path (canvas only) — matches EA exactly.

### 35. Object properties as tagged values

EA stores UML profile tagged values in `t_taggedvalue` (keyed by
ElementID GUID) AND per-object custom properties in
`t_objectproperties` (keyed by Object_ID integer). Both surface as
tagged values in the SVG.

`TaggedValueBuilder#for_object` now takes both `ea_guid` AND
`ea_object_id:` and merges both sources. ClassifierBuilder threads
the integer Object_ID through.

Simple example: AcmeUmlClass tagged values went from 0 to 2
(`noPropertyType=false`, `isCollection=false`), matching EA.

## Current Per-Example Parity Snapshot

| Example  | Text overlap avg | Improvement |
|----------|------------------|-------------|
| plateau  | 87.1%            | (unchanged baseline) |
| arcgis   | ~55%             | +20pp |
| basic    | ~59%             | +5pp |
| simple   | ~85%             | +35pp |
| test     | ~54%             | small |

## Remaining per-example gaps (deferred)

- **ArcGISWorkspace_template**: HTML formatting in note bodies
  (`<ul>`, `<li>`, `<b>`) — we render raw HTML as text, EA strips it.
  Diagram frame title format also differs (we emit "class NAME",
  EA emits "ArcGIS NAME" — package-prefixed).
- **basic**: 19 missing polygons, 30 missing paths. Likely tagged-
  value / signal-classifier-type related.
- **test**: 58 missing paths. Path grouping mode detection
  (TODO-D 27).
