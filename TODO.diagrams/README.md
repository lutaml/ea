# TODO.diagrams — Remaining Work Status

## Completed (recent sessions)

### Architecture & Performance
- [18-property-lookup-index.md](18-property-lookup-index.md) — Document#property_index. 10x speedup.
- [19-replace-respond-to-with-is-a.md](19-replace-respond-to-with-is-a.md) — respond_to? → is_a?(Relationship).
- [20-split-labels-emitter.md](20-split-labels-emitter.md) — Labels split into EndLabel + MidpointLabel + Registry.
- [25-extract-compartment-geometry.md](25-extract-compartment-geometry.md) — Element::CompartmentGeometry extracted.
- [28-architecture-cleanup-batch.md](28-architecture-cleanup-batch.md) — Canvas promoted; OpenStruct removed; specs added.

### Examples Coverage (basic.qea + test.qea focus)
- [32-examples-coverage-batch.md](32-examples-coverage-batch.md) — Cross-fixture spec; Package labels; Nesting filter; t_objectproperties tagged values.
- Signal classifier type with «signal» fallback stereotype.
- Midpoint name rendering (Association A/B names at midpoint).
- Operation parameter types only (op(int): void not op(name: int): void).
- Stereotype wins over association in Label::Registry#midpoint?
- "Object" InstanceSpecification mapping to Klass (basic.qea).
- Nested-class qualified names via ParentID (Class B::Class B.1).
- "object" diagram frame prefix fix.

### Other
- [17-remaining-parity-gaps.md](17-remaining-parity-gaps.md) — High-level parity report.
- [23-marker-polygon-deduplication.md](23-marker-polygon-deduplication.md) — Documented dedup rules.

## Deferred (blocked on external work)

- [21-auto-generated-legend-block.md](21-auto-generated-legend-block.md) — Need EA.exe RE.
- [22-ghost-element-discriminator.md](22-ghost-element-discriminator.md) — Need EA GUI testing.
- [24-marker-anchor-structural.md](24-marker-anchor-structural.md) — Refactor regresses within-tolerance.
- [26-phantom-general-parent-rendering.md](26-phantom-general-parent-rendering.md) — Needs synthetic bounds.
- [27-path-grouping-mode-detection.md](27-path-grouping-mode-detection.md) — No StyleEx toggle.
- [30-decompose-elements-groups_for] — Linear recipe; extraction broke specs twice.
- [36-instance-specification-model.md](36-instance-specification-model.md) — Full UML InstanceSpecification with classifier_ref + slots.
- [37-element-icon-decorations.md](37-element-icon-decorations.md) — Per-row icon shapes need EA.exe RE.
- [38-html-note-and-receptions.md](38-html-note-and-receptions.md) — HTML Note body + Receptions compartment.

## Current Per-Example Parity Snapshot (2026-07-27)

| Example  | Text overlap | Text delta  |
|----------|--------------|-------------|
| plateau  | 87.1%        | -0.2%       |
| simple   | 100%         | 0%          |
| arcgis   | ~55%         | -1.9%       |
| basic    | ~70%         | -7.8%       |
| test     | ~54%         | -10.6%      |

simple.qea is now at **100% text parity** (22/22 texts match).

## Architecture

Code quality rules honored:

- `autoload` for all internal namespaces; no `require_relative`
  outside `lib/ea.rb`'s version constant.
- No `send` / `instance_variable_set` / `instance_variable_get`
  outside framework internals.
- No `respond_to?` (replaced with `is_a?` and polymorphic dispatch).
- No `OpenStruct` (replaced with model value objects).
- Registry pattern for OCP: Marker::Registry, Label::Registry.
- MECE: each label kind in its own class; CompartmentGeometry,
  Canvas, Layer, Background, Signal as proper classes.
- DRY: Document#property_index, wrap_in_text_group, DiagramConnector#renderable?.
- Performance: QEA render time 3.25s → 0.34s (~10x).

## Specs

1685 examples, 0 failures, 52 pending. 35 new examples in
`spec/ea/svg/examples_regression_spec.rb` covering all 5 fixtures.
