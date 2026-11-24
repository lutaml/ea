# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`ea` is a standalone Ruby gem for parsing **Sparx Enterprise Architect** data
files. It parses the EA-native QEA format (SQLite database) and Sparx-flavored
XMI. It does NOT parse generic XMI, MagicDraw XMI, or Papyrus XMI — those have
different idiosyncrasies and belong in their own parser gems.

It optionally integrates with `lutaml-uml` for EA-to-UML model transformation.

**Gem identity**: `ea` (not `lutaml-ea`). Namespace: `Ea::*`. This gem is
usable standalone — `lutaml-uml` is an optional dependency for the UML bridge.

**Dependency graph**:
```
ea (standalone — lutaml-model, lutaml-path, sqlite3, rubyzip, xmi, nokogiri, liquid, thor)
  └── [optional, dev] lutaml-uml (for Ea::Bridge::* → Lutaml::Uml::Document)

lutaml-uml (UML metamodel + UmlRepository + SPA — no dependency on ea)
  └── lutaml-lml
          └── lutaml (meta-bundle)
```

**Architecture — pure parse vs bridge**:

The ea gem has TWO entry points:

```ruby
# PURE — no lutaml-uml dependency. Returns internal EA model.
Ea.parse("model.qea")   # → Ea::Qea::Database (SQLite tables as Ruby models)
Ea.parse("model.xmi")   # → Xmi::Sparx::Root   (xmi gem's typed Sparx model)

# BRIDGE — requires optional lutaml-uml. Returns tool-agnostic UML.
Ea.to_uml("model.qea")  # → Lutaml::Uml::Document (for cross-vendor output)
Ea.to_uml("model.xmi")  # → Lutaml::Uml::Document
```

All lutaml-uml-dependent code lives under `Ea::Bridge::*`:
- `Ea::Bridge::QeaToUml` — transforms Ea::Qea::Database → Lutaml::Uml::Document
- `Ea::Bridge::XmiToUml` — transforms Xmi::Sparx::Root → Lutaml::Uml::Document

The bridge is lazy-loaded — `require "ea"` does NOT load lutaml-uml. Only calling
`Ea.to_uml(...)` (or CLI commands that use it: `ea spa`, `ea diagrams extract`)
triggers the bridge code path.

**Native QEA↔XMI round-trip** (no lutaml-uml):
```
Ea::Transformers::QeaToXmi  — Ea::Qea::Database → Sparx XMI string
Ea::Transformers::UmlToXmi  — Lutaml::Uml::Document → Sparx XMI (bridge)
```

**XMI parsing**: `Ea::Xmi::Parser` is hard-wired to the Sparx schema
(`::Xmi::Sparx::Root.parse_xml`). It cannot parse MagicDraw or Papyrus XMI.
When registering with `UmlRepository`, `ea` registers `.xmi` with content
detection (checks for Sparx EA signatures), so it never claims generic `.xmi`.
See TODO.next/04 and TODO.next/18.

## Build & Development Commands

```bash
bin/setup                    # Install dependencies
bundle exec rake             # Run default task (specs + rubocop)
bundle exec rake spec        # Run tests
bundle exec rspec            # Run tests directly
bundle exec rspec spec/ea/qea/models/ea_object_spec.rb  # Run a single spec file
bundle exec rubocop          # Lint
bundle exec rake install     # Install gem locally
bin/console                  # IRB with gem loaded
```

## Architecture

### Entry Point (`lib/ea.rb`)
Defines `Ea` module with `autoload` for every subsystem. No `require_relative`
anywhere in lib — all internal loading uses `autoload` defined in the
immediate parent namespace file.

### Subsystem map (`lib/ea/`)

| Dir | Purpose | Reached from |
|---|---|---|
| `qea/` | SQLite QEA row models, loader, indexes, repositories | `Ea.parse`, `Ea::Qea.load` |
| `xmi/` | Sparx XMI parsing → `Lutaml::Uml::Document`, Liquid drops | `Ea::Xmi.load`, bridge |
| `bridge/` | `QeaToUml` / `XmiToUml` → `Lutaml::Uml::Document` (optional dep) | `Ea.to_uml` |
| `sources/` | QEA/XMI adapters → canonical `Ea::Model` (hexagon domain) | CLI svg/render/spa/export/query |
| `transformers/` | Native QEA → Sparx XMI round-trip exporter | CLI convert, export xmi |
| `model/` | `Ea::Model` — tool-agnostic domain model | sources consumers |
| `svg/` | EA-faithful SVG emitter (ea_emitter), shapes, markers | CLI svg, diagrams extract |
| `diagram/` | Style resolution, layout, path building | svg emitter |
| `cli/` | Thor CLI (`exe/ea`), 16 commands | `exe/ea` |
| `spa/` | Single-page-app generator (shards, search index) | `ea spa` |
| `diff/` | Structural DB-vs-DB diff with HTML reporter | `ea diff` |
| `export/` | JSON / JSON-Schema / PlantUML / XSD generators | `ea export` |
| `query/` | Chainable element-filter DSL | `ea query` |
| `lint/` | Model quality rule engine | `ea lint` |
| `mdg/` | MDG technology registry/inspection | `ea mdg` |
| `render/` | SVG → PNG/PDF via external tools | `ea render` |
| `fonts/` | Font metrics (shipped JSON width tables) | svg text renderer |
| `image/` | EMF blob → SVG rendering | svg emitter |
| `shapescript/` | EA ShapeScript interpreter for stereotype icons | svg icons |
| `theme/` | Theme registry loading `config/themes/*.yml` | svg emitter |
| `validation/` | `Qea::Validation::ValidationEngine` validators | `ea validate` |
| `ocl/` | OCL constraint parser/evaluator | validation |
| `qea/factory/` | QEA → `Lutaml::Uml::Document` transformers (bridge) | `Ea.to_uml` (.qea) |

### Configuration
- `config/qea_schema.yml` — table enablement, type mappings (loaded by
  `Qea::Services::Configuration`)
- `config/stereotype_colors.yml` — stereotype → color map (svg)
- `config/themes/{default,39,119}.yml` — SVG themes (theme loader)
- `config/diagram_styles.yml`, `config/model_transformations.yml` —
  present but not loaded by any code (kept for reference)

### Standalone Subsystems (no `lutaml-uml` dependency)

#### QEA Core (`lib/ea/qea/`)
- **Models** (25 files) — EA database row models inheriting from `BaseModel`
  (extends `Lutaml::Model::Serializable`). Each model declares attributes,
  `primary_key_column`, `table_name`, and `COLUMN_MAP`. Zero UML references.
- **Infrastructure** — `DatabaseConnection` wraps SQLite3, `SchemaReader`/
  `TableReader` for raw DB access.
- **Services** — `Configuration` loads `config/qea_schema.yml`,
  `DatabaseLoader` loads all tables into a `Database` container.
- **Database** — Immutable container with lazy-built hash indexes for O(1)
  lookups by ID, GUID, foreign keys. Query methods: `constraints_for_object`,
  `tagged_values_for_element`, `properties_for_object`, `xrefs_for_client`.
- **Repositories** — `BaseRepository` provides `Enumerable`, `find`, `where`,
  `pluck`, `group_by`. `ObjectRepository` adds type-specific queries.

#### Diagram Core (`lib/ea/diagram/`)
- **Style** — `StyleResolver` is the single entry point. `StyleParser` parses
  EA style strings. `Configuration` loads `config/diagram_styles.yml`.
- **Layout** — `LayoutEngine` calculates bounds and positioning.
- **Path** — `PathBuilder` generates SVG path data from connector geometry.

### UML-Bridge Subsystems (require `lutaml-uml`)

#### QEA Factory (`lib/ea/qea/factory/`)
- `EaToUmlFactory` orchestrates transformation using `TransformerRegistry`
  for OCP-compliant type dispatch. Each transformer extends `BaseTransformer`.
  `DocumentBuilder` constructs and validates the output `Lutaml::Uml::Document`.
  `ReferenceResolver` maps EA GUIDs to UML xmi_ids.

#### QEA Validation (`lib/ea/qea/validation/`)
- `ValidationEngine` runs registered validators. Validators extend
  `BaseValidator`. Operates on both EA data and UML documents.

#### QEA Verification (`lib/ea/qea/verification/`)
- Document comparison and equivalence testing for QEA vs XMI outputs.

#### Diagram Rendering (`lib/ea/diagram/`)
- **Element Renderers** — Maps element types to renderer classes. `BaseRenderer`
  provides `style_to_css` and template methods. Concrete: `ClassRenderer`,
  `PackageRenderer`, `ConnectorRenderer`.
- **Extractor** — Extracts diagram data from `Lutaml::Uml::Document` instances.

#### XMI Subsystem (`lib/ea/xmi/`)
- `Parser` for **Sparx-flavored** XMI files only (uses `::Xmi::Sparx::Root`).
  Cannot parse MagicDraw or Papyrus XMI. `LookupService` for cross-referencing.
- Liquid drops for template-based XMI rendering.

#### Transformations (`lib/ea/transformations/`)
- `BaseParser` provides template method pattern. Concrete: `QeaParser`,
  `XmiParser`. `FormatRegistry` maps file extensions to parser classes.
  `TransformationEngine` orchestrates parsing. Returns `Lutaml::Uml::Document`.

## Code Quality Rules

- **autoload only** — never `require_relative` or `require` for internal library code
- **No doubles in specs** — use real model instances or `Struct.new`
- **No `send` on private methods** — promote tested methods to public
- **No `instance_variable_get/set`** — test through public API
- **No `respond_to?` or `method_defined?`** — use `is_a?` for type checks, design interfaces properly
- **Registry pattern for OCP** — new types are added by registration, not by modifying `case/when`
- **COLUMN_MAP for models** — database column mapping uses the `COLUMN_MAP` constant pattern, not custom `from_db_row` overrides

## Configuration

- Ruby >= 3.2.0 (CI tests on 3.4.8)
- Double-quoted strings enforced by RuboCop
- RSpec: documentation formatter, color enabled, status persistence to `.rspec_status`
