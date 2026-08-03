# TODO-D 15 - Deep dead code audit

## Status: COMPLETE (2026-07-27)

## Audit findings

All production subsystems in `lib/ea/` are actively used:

| Subsystem | Used by | Status |
|---|---|---|
| `Ea::Model` | All adapters and renderers | KEEP |
| `Ea::Sources::Qea` | `Ea.parse`, `Ea::Sources::Qea::Adapter.from_path` | KEEP |
| `Ea::Sources::Xmi` | `Ea::Sources::Xmi::Adapter.from_path` | KEEP |
| `Ea::Svg::EaEmitter` | `ea svg` CLI command | KEEP |
| `Ea::Theme` | Diagram.theme resolution | KEEP |
| `Ea::Diagram::DisplayConfig` | `Diagram#display_config` | KEEP |
| `Ea::Qea` (SQLite layer) | `Ea::Sources::Qea::*` adapters | KEEP |
| `Ea::Xmi` | `Ea::Sources::Xmi::*` adapters | KEEP |
| `Ea::Spa` | `ea spa` CLI command | KEEP |
| `Ea::Transformers` | `ea convert` CLI command | KEEP |
| `Ea::Bridge` | `Ea::Transformations.to_uml` | KEEP |
| `Ea::Transformations` | `RepositoryBuilder` for bridge CLI | KEEP |

## Code quality audit

| Rule | Status |
|---|---|
| No `send` to call private methods | CLEAN |
| No `instance_variable_set`/`get` | CLEAN (only mentioned in a comment) |
| No `respond_to?` for type checks | CLEAN (replaced with `is_a?` earlier) |
| No `require_relative` for library code | CLEAN (one in `lib/ea.rb` for VERSION — standard gemspec pattern) |
| autoload for all internal loading | CLEAN |

## Architecture observations

The codebase follows OCP well:
- `Marker::Kind` subclasses registered via `Marker::Registry.register`
- `Theme::Definition` immutable value object with `#with` for variants
- `Theme::Registry` auto-loads from `config/themes/*.yml`
- `Element::*Renderer` classes are independent — adding a new
  compartment type doesn't modify existing renderers

## DRY

Found one minor duplication: `Labels` and `AttributeRenderer` both
have text-emission logic. Consolidated into shared `TextRenderer`
calls. No further DRY violations observed.
