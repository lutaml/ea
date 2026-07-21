# 11 - ElkRb Auto-Layout Integration

## Status: TODO (post-PR #24)

## Problem

The current Ea::Svg::EaEmitter renders diagrams from the placement
data captured by the source adapter (QEA's t_diagramobjects /
t_diagramlinks, XMI's <xmi:Extension>/<elements>). When the source
doesn't carry placement data — or when the user wants to re-layout
an existing diagram — there's no fallback.

Eclipse Layout Kernel (ELK) is the standard auto-layout library for
node-link diagrams (UML class diagrams, flowcharts, etc.). `elkrb`
is a pure-Ruby implementation in `/Users/mulgogi/src/claricle/elkrb/`.

## Approach

Build an `Ea::Layout::ElkAdapter` that:

1. Translates an `Ea::Model::Document` (or a subset — packages,
   classifiers, relationships) into elkrb's `Graph` / `Node` /
   `Edge` model.
2. Runs the chosen elkrb algorithm (`Layered` for class diagrams
   is the Sugiyama-style default; `Force` for organic; `Stress`
   for high-quality).
3. Reads back the computed positions and writes them into an
   `Ea::Model::Diagram` (with DiagramElement bounds and
   DiagramConnector waypoints computed by elkrb's edge router).

Then the standard `Ea::Svg::EaEmitter` renders the layout-posed
diagram just like an EA-authored one. No renderer changes needed.

CLI surface:
- `ea layout FILE [--algorithm=layered|force|stress]` — runs
  auto-layout, emits a JSON of computed positions
- `ea svg NAME FILE --layout=auto` — runs layout then renders

## Files

- `lib/ea/layout.rb` (namespace)
- `lib/ea/layout/elk_adapter.rb`
- `lib/ea/layout/document_to_graph.rb`
- `lib/ea/layout/graph_to_diagram.rb`
- `lib/ea/cli/command/layout.rb`
- `spec/ea/layout/*_spec.rb`

## Verification

- Spec: known small document → elk graph → known layout output.
- Spec: QEA fixture with no placement data → auto-layout produces
  non-overlapping positions.
- Spec: round-trip — auto-layout, render to SVG, no errors.
