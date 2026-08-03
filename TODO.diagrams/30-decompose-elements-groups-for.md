# TODO-D 30: Decompose Elements groups_for (DONE)

## Goal

The `Elements#groups_for` method had grown to ~100 lines, mixing
shape dispatch, header rendering, divider logic, attribute /
operation / enum-literal / tagged-value compartment rendering,
and special-case branching for Note bodies.

## Implementation

Extracted a Compartment pipeline:

```
Elements#groups_for(element)
  └─ build_context(element) → RenderContext
  └─ Compartment.render_all(context) → Array<String>
       ├─ Compartment::Shape
       ├─ Compartment::NoteBody
       ├─ Compartment::Header
       ├─ Compartment::HeaderDivider
       ├─ Compartment::Attributes
       ├─ Compartment::Operations
       ├─ Compartment::EnumLiterals
       └─ Compartment::TaggedValues
```

- `RenderContext` (Struct): immutable per-element state — bounds,
  classifier, fill/stroke, font, geometry, line arrays, theme,
  canvas. Built once, passed to every compartment.
- `Compartment::ALL`: frozen list of compartment modules in EA's
  render order. Adding a new compartment = appending a module to
  this list. Elements does not change.
- Each compartment is a Module with `module_function :render`.
  Returns nil when the compartment does not apply (no content,
  no geometry). The pipeline compacts the result.

## Benefits

- **OCP**: new compartments don't modify Elements#groups_for.
- **SRP**: each compartment knows one concern.
- **Testability**: each compartment has a focused spec.
- **Readability**: Elements went from ~377 lines to ~232 lines;
  groups_for went from ~100 lines to ~10.

## Verification

- All 1694 existing specs pass.
- New specs: `spec/ea/svg/ea_emitter/compartment_spec.rb` covers
  the pipeline ordering and RenderContext helpers.
- Parity bench unchanged: rect -221, path -280, polygon -6,
  text -601, overlap 64.5%. The refactor is behavior-preserving.
