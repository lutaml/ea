# 05 - Marker Registry (OCP)

## Status: DONE (2026-07-24)

## Outcome

Refactored marker dispatch from case/when to a Registry of Kind
classes. `Marker::Registry.register(kind)` adds a new kind;
`Registry.specs_for(connector, effective_type, ...)` returns the
Spec list from the first kind that handles the type.

Built-in kinds (registered in priority order):
- `Marker::Diamond` — Aggregation, Composition (emits diamond +
  arrow specs)
- `Marker::OpenTriangle` — Generalization, Realization, Dependency
- `Marker::ArrowPath` — Association navigability arrow

Adding a new kind = creating a Kind subclass + calling
`Marker::Registry.register(MyKind)`. No modification of existing
code (OCP).

## Files changed

- `lib/ea/svg/ea_emitter/marker.rb` — module entry + registration
- `lib/ea/svg/ea_emitter/marker/kind.rb` — base Kind class
- `lib/ea/svg/ea_emitter/marker/registry.rb` — Registry + Spec
- `lib/ea/svg/ea_emitter/marker/diamond.rb` — Diamond kind
- `lib/ea/svg/ea_emitter/marker/open_triangle.rb` — OpenTriangle kind
- `lib/ea/svg/ea_emitter/marker/arrow_path.rb` — ArrowPath kind
- `lib/ea/svg/ea_emitter.rb` — autoload Marker
- `lib/ea/svg/ea_emitter/markers.rb` — delegates to Registry
- `spec/ea/svg/ea_emitter/marker/registry_spec.rb` — 6 specs incl OCP
