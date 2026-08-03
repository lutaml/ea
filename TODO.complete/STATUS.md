# TODO.complete — Strategic Work Catalog

The `ea` gem's goal: become a headless, cross-platform CLI replacement for
Sparx Enterprise Architect. EA requires Windows + paid license; the `ea`
gem runs anywhere Ruby runs.

## Current state (2026-08-03)

- **Parsing**: 43 QEA tables covered (43 / ~96).
- **Diagram rendering**: basic.qea 100% pixel-perfect; plateau 167/188.
- **MDG technologies**: loader + registry + alias resolver functional.
- **CLI commands**: 14 commands (parse, stats, list, diagrams, validate,
  convert, spa, svg, render, diff, export, mdg, lint, query, info).
- **Export**: XMI (via full Transformers::QeaToXmi + ExtensionSerializer),
  JSON (curated), JSON Schema, PlantUML (with packages + relationships),
  XSD.
- **ShapeScript**: parser + renderer (vars, arithmetic, conditionals,
  subshapes, labels). Wired into StereotypeIconRenderer.
- **OCL evaluator**: invariant subset (exists, forAll, matches,
  size, isEmpty, comparison ops), wired into `ea validate`.
- **Lint**: 5 rules.
- **Query DSL**: chainable Builder.
- **Image**: t_image loading + EmfRenderer wired into Document emitter.
- **Stereotype icons**: StereotypeIconRenderer wired as compartment.
- **HeaderLines**: OCP provider chain.
- **Diff**: text + HTML report; detects added/removed/renamed/modified.
- **Specs**: 2200+ examples, 0 failures, 55 pending.
- **Code quality**: zero `respond_to?`, zero `instance_variable_get/set`,
  zero `require_relative` in lib code, zero internal `require` (all
  autoload).

## Work streams — all completed (51–63: real completion work)

### Stream A — Data Model Completeness
01–07, 44 — all done.

### Stream B — MDG / Stereotype System
10, 11, 13, 36, 45, 46 — all done.

### Stream C — CLI Commands
20–24, 37–39, 42, 43 — all done.

### Stream D — Architecture & Code Quality
30–33, 40, 41, 47 — all done.

### Stream F — Real Completion Work (this session)

| # | File | Title | Status |
|---|---|---|---|
| 51 | [51-remove-respond-to.md](51-remove-respond-to.md) | Remove `respond_to?` from lib code | **completed** |
| 52 | [52-xsd-decouple-fixtures.md](52-xsd-decouple-fixtures.md) | Decouple XSD Generator from fixtures | **completed** |
| 53 | [53-xmi-public-send-cleanup.md](53-xmi-public-send-cleanup.md) | xmi/parser `public_send` cleanup | **deferred** (no encapsulation violation; needs upstream) |
| 54 | [54-wire-stereotype-icon-renderer.md](54-wire-stereotype-icon-renderer.md) | Wire StereotypeIconRenderer into SVG emitter | **completed** |
| 55 | [55-wire-shapescript.md](55-wire-shapescript.md) | Wire ShapeScript into StereotypeIconRenderer | **completed** |
| 56 | [56-wire-emf-renderer.md](56-wire-emf-renderer.md) | Wire EmfRenderer into SVG emitter | **completed** |
| 57 | [57-wire-ocl-evaluator.md](57-wire-ocl-evaluator.md) | Wire OCL evaluator into `ea validate` | **completed** |
| 58 | [58-diff-modifications.md](58-diff-modifications.md) | Diff comparator detects modifications | **completed** |
| 59 | [59-delete-toy-xmi-export.md](59-delete-toy-xmi-export.md) | Delete toy XMI export; route to Transformers | **completed** |
| 60 | [60-curate-json-export.md](60-curate-json-export.md) | Curated JSON export schema | **completed** |
| 61 | [61-plantuml-relationships.md](61-plantuml-relationships.md) | PlantUML with packages + relationships | **completed** |
| 62 | [62-changelog.md](62-changelog.md) | CHANGELOG.md | **completed** |
| 63 | [63-dependabot-fix.md](63-dependabot-fix.md) | Dependabot vulnerability | **completed** (lychee-action v1 → v2) |

### Stream G — Parity + Code Quality (this session)

| # | File | Title | Status |
|---|---|---|---|
| 64 | [64-qeatoxmi-connectors.md](64-qeatoxmi-connectors.md) | QeaToXmi emits connectors | **done** (via 66) |
| 65 | [65-qeatoxmi-diagrams.md](65-qeatoxmi-diagrams.md) | QeaToXmi emits diagrams | **done** (via 66) |
| 66 | [66-qeatoxmi-style-tags-docs.md](66-qeatoxmi-style-tags-docs.md) | QeaToXmi ExtensionSerializer | **done** |
| 67 | [67-ocl-collection-ops.md](67-ocl-collection-ops.md) | OCL size/isEmpty | **done** |
| 68 | [68-ocl-comparison-ops.md](68-ocl-comparison-ops.md) | OCL comparison operators | **done** |
| 69 | [69-spec-new-models.md](69-spec-new-models.md) | Specs for 13 new QEA models | **done** |
| 70 | [70-specs-for-all-models.md](70-specs-for-all-models.md) | Specs for 18 remaining models | **done** |
| 71 | [71-autoload-audit.md](71-autoload-audit.md) | Autoload audit | **done** |
| 72 | [72-extension-serializer-ocp-naming.md](72-extension-serializer-ocp-naming.md) | ExtensionSerializer OCP + naming | **done** |
| 73 | [73-ocl-validator-latent-bugs.md](73-ocl-validator-latent-bugs.md) | OCL validator latent bugs | **done** |
| 74 | [74-visibility-symbol-dry.md](74-visibility-symbol-dry.md) | Visibility symbol DRY extraction | **done** |
| 75 | [75-database-table-collection-registry.md](75-database-table-collection-registry.md) | Database table→collection registry (MECE) | **done** |
| 76 | [76-stale-todo-cleanup.md](76-stale-todo-cleanup.md) | Stale TODO status cleanup (40 items) | **done** |

### Bonus (no TODO file; found during 51)

- Renamed `object_id` attribute to `ea_object_id` in 12 new QEA models
  (Ruby `Object#object_id` collision).

## CLI command summary (14 commands)

```
ea parse FILE              Parse to Lutaml::Uml::Document
ea stats FILE              Show collection counts
ea list FILE               List model elements
ea diagrams ACTION FILE    Diagram list / extract
ea validate FILE           Validate model (incl. OCL constraints)
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
