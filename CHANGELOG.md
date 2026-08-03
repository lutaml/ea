# Changelog

All notable changes to the `ea` gem are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] — 2026-08-03

### Added — CLI commands (13 new)
- `ea diff OLD NEW` — structural comparison of two QEA files
  (`--format=html` produces a color-coded HTML report).
- `ea render NAME FILE` — unified rendering (SVG/PNG/PDF via
  rsvg-convert or ImageMagick).
- `ea export SUB FILE` — exports: `xmi`, `json`, `json-schema`,
  `plantuml`, `xsd`.
- `ea mdg ACTION` — list registered MDG technologies, show
  stereotype details, list all stereotypes.
- `ea lint FILE` — model quality checks (naming convention,
  orphan elements, duplicate names, cyclic generalizations,
  missing stereotypes).
- `ea query FILE` — filter elements via a chainable DSL
  (by type, package, stereotype, name).
- `ea info NAME FILE` — show details of a single element.

### Added — Subsystems
- `Ea::Sources::Qea::Xref` — parser for `t_xref.Description`
  (stereotype applications, tagged-value specs, legend definitions).
- `Ea::Mdg::StereotypeAliasRegistry` — canonicalizes variant
  stereotype spellings via GMLStereotypes.xml.
- `Ea::Export::Xsd::Generator` — GMLClassMapping-driven XSD
  schema generation.
- `Ea::Export::JsonSchema::Generator` — JSON Schema (draft
  2020-12) export.
- `Ea::Export::Json::Generator`, `Ea::Export::PlantUml::Generator`
  — JSON and PlantUML exports.
- `Ea::Image::EmfRenderer` — lazy emfsvg adapter for EMF→SVG.
- `Ea::Render::ImageConverter` — SVG → PNG / PDF via system tools.
- `Ea::Lint` — engine + 5 rules (OCP: new rule = new class).
- `Ea::Ocl` — OCL invariant parser + evaluator (subset: exists,
  forAll, matches, and/or/not, attribute access).
- `Ea::Shapescript` — ShapeScript parser + renderer with
  variables, arithmetic, conditionals, subshapes, labels.
- `Ea::Svg::EaEmitter::Element::HeaderLinePipeline` — OCP-friendly
  provider chain replacing the monolithic HeaderLines module.
- `Ea::Svg::EaEmitter::Element::StereotypeIconRenderer` — emits
  stereotype decorator icons inside element bodies.

### Added — QEA table coverage (24 → 43 tables)
- `t_image`, `t_glossary`, `t_lists`, `t_versions`, `t_phase`,
  `t_authors`, `t_secrypt`, `t_palette`, `t_paletteitem`,
  `t_implement`, `t_roleconstraint`, `t_objectproblems`,
  `t_objectrisks`, `t_objecttests`, `t_objecteffort`,
  `t_objectresource`, `t_objectscenarios`, `t_objectrequires`,
  `t_objecttrx`.

### Changed
- `Ea::Svg::EaEmitter::Element::HeaderLines` is now a thin alias
  to the new `HeaderLinePipeline` (OCP provider chain).
- Per-label styling fields (`BLD`, `ITA`, `UND`, `CLR`, `ALN`,
  `DIR`, `ROT`) parsed from `t_diagramlinks.Geometry`.
- Six new PDATA flag accessors on `Ea::Diagram::DisplayConfig`:
  `ShowEStereo`, `ShowSN`, `OpParams`, `UseAlias`, `SuppCN`,
  `ShowCons`, `ScalePI`.
- `TableReader#table_exists?` — DatabaseLoader skips missing
  tables gracefully instead of raising.
- `Ea::Export::Xmi` removed — `ea export xmi` now routes through
  the established `Ea::Transformers::QeaToXmi` (full-fidelity
  Sparx round-trip) instead of a toy generator.

### Removed
- `Ea::Codegen` — speculative. We don't know what EA's actual
  codegen does, so building our own was wrong.
- Plugin system TODO — not needed.
- Liquid template integration TODO — `lutaml-model` already
  supports liquid drops natively.

### Fixed
- Replaced all `respond_to?` calls in lib code with `is_a?`
  type checks.
- Renamed `object_id` attribute to `ea_object_id` in 12 new
  QEA models to avoid collision with Ruby's `Object#object_id`.

### Spec coverage
- 1974 examples, 0 failures, 55 pending.

## [0.4.0] — 2026-07-21

Initial public release of the standalone parser (QEA + Sparx XMI),
diagram SVG rendering, and UML bridge.

## [0.1.0] — 2026-05-23

- Initial release
