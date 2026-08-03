# TODO-D 28-31: Architectural cleanup batch

## Completed (this session)

### 28. Canvas promoted to proper class

`lib/ea/svg/ea_emitter/canvas.rb` was a `Struct.new + do ... end`
block. Promoted to an explicit class with `attr_reader` for the
four bound fields. Public API is now named rather than implicit;
the type stays immutable.

8 new specs cover `translate_x`, `translate_y`, `.coord`,
immutability, and the existing `.from` factory.

### 29. OpenStruct removed

`elements.rb#translate_bounds` returned an `OpenStruct.new`. This
required `require "ostruct"` at the top of the file and obscured
the return type.

Now returns `Ea::Model::Bounds.new` directly — the existing model
value object — and the `require "ostruct"` line is removed. Type
flows cleanly through the pipeline (model → renderer).

### 31. Specs for under-tested components

- `spec/ea/svg/ea_emitter/canvas_spec.rb` — added `translate_x`,
  `translate_y`, `.coord`, and immutability specs.
- `spec/ea/svg/ea_emitter/layer_spec.rb` — new file (10 specs).
- `spec/ea/svg/ea_emitter/background_spec.rb` — new file (3 specs).

## Deferred

### 30. Decompose Elements groups_for

`Elements#groups_for` is ~100 lines of linear rendering steps.
Two previous attempts to extract a helper method broke 5+ specs
due to complex parameter threading (model_element vs classifier
distinction, Optional bounds, theme plumbing).

The method reads as a recipe: each step adds one output string.
Linear recipes are easier to read as one method than as a chain
of helper calls with overlapping parameter lists.

Deferred until a structural refactor (e.g. a Compartments
collaborator that holds rendering state) is justified by a new
requirement.
