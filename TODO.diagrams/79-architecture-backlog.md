# TODO-D 79: Architecture improvements backlog

## Status: open (rolling)

A list of architecture / code-quality improvements surfaced while
closing parity gaps. Each is shippable independently.

## 1. Elements#build_context decomposition

`Elements#build_context` (lib/ea/svg/ea_emitter/elements.rb) is
~50 lines and growing. It now also resolves the off-canvas parent
name, adding a new concern. Extract collaborators:

  - `HeaderInputResolver` — gathers inputs for HeaderLines
    (visually_nested, parent_name, umldi_keyword, bounds_width).
  - `CompartmentInputResolver` — gathers attr_lines/op_lines/etc.

Each returns a small Struct; `build_context` just assembles them
into the RenderContext.

## 2. RenderContext struct field count

RenderContext carries 23 keyword fields. Some are mutually relevant
(e.g., `attr_lines` and `geometry.attr_lines_count`). Consider
grouping:

  - `HeaderInput` struct (header_lines, off_canvas_parent_name)
  - `CompartmentInput` struct (attr_lines, op_lines, enum_literals,
    tagged_values, constraints, package_content_lines)

Fewer top-level fields, clearer purpose per group.

## 3. Phantom connector label boxes

`DiagramBuilder::DEFAULT_LABEL_BOXES` is a constant in the builder.
The geometry belongs on the synthesized DiagramConnector model
field (e.g., `default_label_offsets: true`). Currently the
`has_geometry_offsets` flag conveys this for one case; generalize.

## 4. LayerSequencer dependency threading

LayerSequencer takes `document:` and threads it to multiple
collaborators (Labels, Elements). The collaborators individually
re-fetch relationships from the document. A precomputed per-diagram
"parent_index" (child_id → parent_id) built once at DiagramBuilder
time would remove the per-render relationship scan.

## 5. public_send in Qea::Repositories::BaseRepository

`BaseRepository` uses `public_send(attr)` for dynamic attribute
dispatch. This is intentional metaprogramming (the attribute name
is data), not type-checking. But it's worth documenting with a
comment so future readers don't mistake it for the forbidden
private-send pattern.

## 6. Spec coverage for new code

New code added in TODO-D 71 (off-canvas parent ghost line):
  - `Elements#off_canvas_parent_name_for` — no spec
  - `Elements#parent_generalization_for` — no spec
  - `Elements#parent_package_represented_on_diagram?` — no spec
  - `HeaderLines` italic prepend — covered indirectly via existing
    header_lines_spec.

Add specs for the three Elements methods.
