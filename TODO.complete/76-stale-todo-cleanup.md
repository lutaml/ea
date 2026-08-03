# TODO.complete/76: Stale TODO status cleanup

## Status: done

40 TODOs in `TODO.complete/` were marked "open" or "deferred" but
were actually fully implemented with passing specs. This batch
updates their status to "done" to reflect reality.

## TODOs updated to done

| # | Title | Evidence |
|---|-------|----------|
| 01 | t_xref parsing | `lib/ea/sources/qea/xref/` namespace with parser+record+5 value objects |
| 02 | per-label geometry | `lib/ea/svg/ea_emitter/label/` infrastructure complete |
| 03 | object properties/constraints | `EaObjectProperty`, `EaObjectConstraint` models |
| 04 | operation params | `EaOperationParam` model + specs |
| 05 | pdata flag matrix | 10 pdata fields on `EaObject` |
| 06 | EMF image rendering | `lib/ea/image/emf_renderer.rb` + specs |
| 07 | auxiliary tables | 44 models covering all main EA tables |
| 10 | MDG stereotype registry | `lib/ea/mdg/loader.rb` + registry + specs |
| 11 | GML/XSD generation | `lib/ea/export/xsd/generator.rb` |
| 13 | ShapeScript interpreter | `lib/ea/shapescript/` — parser+renderer, 21 specs |
| 20-23 | CLI commands | diff, render, export, mdg commands exist |
| 30 | headerlines OCP | `header_line_provider/` with provider chain |
| 32 | spec coverage | 166 spec files, 2160+ examples |
| 33 | blocked parity gaps | informational; gaps tracked in parity spec |
| 36 | stereotype icon wiring | `stereotype_icon_renderer.rb` |
| 37-39 | CLI lint/query/info | commands exist + specs |
| 40 | OCL evaluator | `lib/ea/ocl/` with parser+evaluator+nodes |
| 41 | round-trip spec | `spec/ea/integration/round_trip_spec.rb` |
| 42 | HTML diff report | `lib/ea/diff/html_reporter.rb` |
| 43 | JSON schema export | `lib/ea/export/json_schema/generator.rb` |
| 44 | remaining QEA tables | 44 models total |
| 45 | shapescript extensions | vars, arithmetic, conditionals, subshapes, labels |
| 46 | XSD consolidation | namespace_registry + class_mapping modules |
| 47 | headerlines legacy removal | provider chain replaces old inline logic |
| 52 | XSD decouple fixtures | XSD generator spec works without fixture coupling |
| 54-57 | wire renderers | stereotype icon, shapescript, EMF, OCL all wired |
| 58 | diff modifications | `compare_modifications` in comparator.rb |
| 59 | delete toy XMI export | routed through Transformers |
| 60 | curate JSON export | PROJECTORS hash with per-model schemas |
| 61 | PlantUML relationships | connector_lines with generalization/association |
| 62 | changelog | CHANGELOG.md exists |
| 63 | dependabot fix | lychee-action@v2 |

## TODOs left with rationale

- **31** (public_send cleanup): partially complete — `public_send`
  only calls public methods (no encapsulation violation). Remaining
  sites are legitimate dynamic dispatch.
- **53** (xmi/parser public_send): deferred — needs upstream xmi
  gem wrapper. All 11 sites call public xmi gem methods.
