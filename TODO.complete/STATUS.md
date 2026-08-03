# TODO.complete — Strategic Work Catalog

The `ea` gem's goal: become a headless, cross-platform CLI replacement for
Sparx Enterprise Architect. EA requires Windows + paid license; the `ea`
gem runs anywhere Ruby runs.

## Current state (2026-08-03)

- **Parsing**: 43/96 QEA tables covered (glossary, lists, versions, phase,
  authors, image, secrypt, palette, paletteitem, implement, roleconstraint,
  objectproblems/risks/tests/efforts/resources/scenarios/requires/trx).
- **Diagram rendering**: basic.qea 100% pixel-perfect; plateau 167/188
  pixel-perfect.
- **MDG technologies**: loader + registry + alias resolver functional.
- **CLI commands**: 14 commands (parse, stats, list, diagrams, validate,
  convert, spa, svg, render, diff, export, mdg, lint, query, info).
- **Export**: XMI, JSON, JSON Schema, PlantUML, XSD.
- **ShapeScript**: parser + renderer with variables, arithmetic,
  conditionals, subshapes, labels.
- **OCL evaluator**: invariant subset (exists, forAll, matches, and/or/not).
- **Lint**: 5 rules (naming, orphan, duplicate, cyclic, missing-stereotype).
- **Query DSL**: chainable Builder.
- **Image**: t_image loading + lazy emfsvg adapter.
- **Render pipeline**: SVG default, PNG/PDF via rsvg/ImageMagick.
- **HeaderLines**: OCP provider chain.
- **Diff**: text + HTML report.
- **Specs**: 1974 examples, 0 failures, 55 pending.

## Out of scope (will not implement)

- **Code generation from MDG templates** — we don't know what EA's
  codegen actually does, so building our own would be speculative.
  Removed.
- **Liquid template integration** — lutaml-model already supports
  liquid drops natively; nothing to add.
- **Plugin system for user-supplied generators** — not needed.

## Work streams — all completed

### Stream A — Data Model Completeness

| # | File | Title | Status |
|---|---|---|---|
| 01 | [01-t-xref-parsing.md](01-t-xref-parsing.md) | Full t_xref parser | **completed** |
| 02 | [02-per-label-geometry.md](02-per-label-geometry.md) | Per-label Geometry box parsing | **completed** |
| 03 | [03-object-properties-constraints.md](03-object-properties-constraints.md) | t_objectproperties + t_objectconstraint | **completed** |
| 04 | [04-operation-params.md](04-operation-params.md) | t_operationparams parsing | **completed** |
| 05 | [05-pdata-flag-matrix.md](05-pdata-flag-matrix.md) | PDATA/StyleEx flag matrix | **completed** |
| 06 | [06-emf-image-rendering.md](06-emf-image-rendering.md) | EMF→SVG via emfsvg gem | **completed** |
| 07 | [07-auxiliary-tables.md](07-auxiliary-tables.md) | Glossary, versions, phase, lists, authors | **completed** |
| 44 | [44-remaining-qea-tables.md](44-remaining-qea-tables.md) | 13 more tables | **completed** |

### Stream B — MDG / Stereotype System

| # | File | Title | Status |
|---|---|---|---|
| 10 | [10-mdg-stereotype-registry.md](10-mdg-stereotype-registry.md) | MDG stereotype registry | **completed** |
| 11 | [11-gml-xsd-generation.md](11-gml-xsd-generation.md) | GML XSD schema generation | **completed** |
| 13 | [13-shapescript-interpreter.md](13-shapescript-interpreter.md) | ShapeScript interpreter | **completed** |
| 36 | [36-stereotype-icon-wiring.md](36-stereotype-icon-wiring.md) | Stereotype icon renderer | **completed** |
| 45 | [45-shapescript-extensions.md](45-shapescript-extensions.md) | Vars, arithmetic, conditionals | **completed** |
| 46 | [46-xsd-consolidation.md](46-xsd-consolidation.md) | CliBridge removed | **completed** |

### Stream C — CLI Commands

| # | File | Title | Status |
|---|---|---|---|
| 20 | [20-cli-diff.md](20-cli-diff.md) | `ea diff` | **completed** |
| 21 | [21-cli-render.md](21-cli-render.md) | `ea render` svg/png/pdf | **completed** |
| 22 | [22-cli-export.md](22-cli-export.md) | `ea export` xmi/json/json-schema/plantuml/xsd | **completed** |
| 23 | [23-cli-mdg.md](23-cli-mdg.md) | `ea mdg list/show/stereotypes` | **completed** |
| 37 | [37-cli-lint.md](37-cli-lint.md) | `ea lint` | **completed** |
| 38 | [38-cli-query.md](38-cli-query.md) | `ea query` | **completed** |
| 39 | [39-cli-info.md](39-cli-info.md) | `ea info NAME` | **completed** |
| 42 | [42-html-diff-report.md](42-html-diff-report.md) | `ea diff --format=html` | **completed** |
| 43 | [43-json-schema-export.md](43-json-schema-export.md) | JSON Schema export | **completed** |

### Stream D — Architecture & Code Quality

| # | File | Title | Status |
|---|---|---|---|
| 30 | [30-headerlines-ocp-refactor.md](30-headerlines-ocp-refactor.md) | HeaderLines → provider chain | **completed** |
| 31 | [31-public-send-cleanup.md](31-public-send-cleanup.md) | Eliminate public_send | **completed** |
| 32 | [32-spec-coverage.md](32-spec-coverage.md) | Specs for new code | **completed** |
| 33 | [33-blocked-parity-gaps.md](33-blocked-parity-gaps.md) | Blocked gaps documented | **completed** |
| 40 | [40-ocl-evaluator.md](40-ocl-evaluator.md) | OCL evaluator | **completed** |
| 41 | [41-round-trip-spec.md](41-round-trip-spec.md) | Round-trip stability | **completed** |
| 47 | [47-headerlines-legacy-removal.md](47-headerlines-legacy-removal.md) | HeaderLines alias | **completed** |

## CLI command summary (14 commands)

```
ea parse FILE              Parse to Lutaml::Uml::Document
ea stats FILE              Show collection counts
ea list FILE               List model elements
ea diagrams ACTION FILE    Diagram list / extract
ea validate FILE           Validate model
ea convert FILE --to=xmi   Convert QEA ↔ XMI
ea spa FILE                Generate SPA HTML
ea svg NAME FILE           Render single SVG
ea render NAME FILE        Render to svg/png/pdf
ea diff OLD NEW            Structural comparison (--format=html)
ea export SUB FILE         xmi | json | json-schema | plantuml | xsd
ea mdg ACTION              list | show NAME | stereotypes
ea lint FILE               Model quality lint
ea query FILE              Filter elements
ea info NAME FILE          Show element details
ea version                 Show version
```
