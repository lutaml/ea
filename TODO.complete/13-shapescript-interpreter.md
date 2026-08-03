# TODO.complete/13: Basic ShapeScript interpreter

## Status: done

ShapeScript parser + renderer implemented with vars, arithmetic,
conditionals, subshapes, and labels. Wired into
StereotypeIconRenderer for stereotype decorator icons.

## Implementation

- `lib/ea/shapescript/parser.rb` — tokenizes and parses ShapeScript
  source into `Shape` value objects.
- `lib/ea/shapescript/shape.rb` — `Shape` model (rect, polygon,
  ellipse, line, text).
- `lib/ea/shapescript/renderer.rb` — walks a parsed `Shape` tree and
  emits SVG elements.
- 21 specs in `spec/ea/shapescript/shapescript_spec.rb` (0 failures).
