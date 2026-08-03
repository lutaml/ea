# TODO-D 78: Refactor HeaderLines into provider chain (OCP)

## Status: open (architecture improvement)

The current `HeaderLines.for` accepts a growing list of kwargs:

```ruby
def for(classifier,
        diagram_package_id: nil,
        visually_nested: false,
        umldi_keyword: nil,
        bounds_width: nil,
        font_size: 9,
        off_canvas_parent_name: nil)  # added in TODO-D 71
  ...
end
```

Adding the off-canvas parent line required:
1. A new kwarg on `for`
2. New logic inside `for` to prepend the line
3. Threading the value from `Elements#build_context` through `RenderContext`

This is OCP-violating: each new header line variant (e.g., "realized
interfaces", "template parameters", "constraint summary") would
require modifying `HeaderLines.for` again.

## Proposed refactor

Convert `HeaderLines` into a chain of line providers, each
contributing 0+ lines to the header. New line types = new provider
class, registered into the chain (no modification of existing
code).

```ruby
module Element
  module HeaderLineProvider
    ALL = [
      StereotypeLine,        # «FeatureType» line (when present)
      ParentClassLine,       # italic off-canvas parent (TODO-D 71)
      QualifiedNameLine,     # the bold class name (with optional wrap)
    ].freeze

    def self.lines_for(classifier, context:)
      ALL.flat_map { |provider| provider.lines_for(classifier, context) }
    end
  end
end
```

Where `context` is a small Struct carrying the inputs each provider
may need (diagram_package_id, visually_nested, off_canvas_parent_name,
bounds_width, font_size, etc.).

## Benefit

Adding a new line type (e.g., "interface signatures" on Interface
classifiers) becomes a single new provider class — `HeaderLines.for`
never changes.

## Migration

Incremental: extract one provider at a time, starting with the
off-canvas parent line (the most recent addition). Each extraction
is independently shippable.
