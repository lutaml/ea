# TODO.complete/84: OCP — markers.rb shape dispatch → registry

## Status: done

`Markers` had 3 case/when blocks all dispatching on the same
`spec.shape` enum. Adding a new marker shape required editing 3
methods — a classic OCP violation.

## Before

```ruby
def style_for(key)
  case key
  when :diamond_filled then "..."
  when :triangle_open then "..."
  when :connector_line then "..."
  end
end

def style_key_for(spec)
  case spec.shape
  when :diamond then :diamond_filled
  when :triangle then :triangle_open
  when :plus then :connector_line
  ...
  end
end

def render_shape(spec)
  case spec.shape
  when :diamond then diamond_polygon(spec.anchor, spec.base)
  when :triangle then triangle_polygon(spec.anchor, spec.base)
  ...
  end
end
```

## After

Two OCP registries: `SHAPE_REGISTRY` (shape → style_key + render
lambda) and `STYLE_MAP` (style_key → fill/opacity). Adding a new
marker shape = adding one entry to `SHAPE_REGISTRY`. Adding a new
style = adding one entry to `STYLE_MAP`. No existing code edited.

The render methods (`diamond_polygon`, `triangle_polygon`, etc.)
were promoted from private to public via `public :method` — they're
now called from the SHAPE_REGISTRY lambdas, so per the user's rule
("promote tested methods to public") they must be accessible.

## Acceptance

- All 293 SVG emitter specs pass (0 failures).
- Full suite: 2211 examples, 0 failures, 55 pending.
- Adding a new marker shape = 1 hash entry, not 3 case/when edits.
