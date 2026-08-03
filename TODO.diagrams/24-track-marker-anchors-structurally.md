# TODO-D 24: Track marker anchors structurally (DONE)

## Before

`Markers#anchor_key` parsed the rendered SVG string with regex to
extract the marker's anchor coordinates:

```ruby
def anchor_key(body)
  match = body.match(/polygon points="(-?[\d.]+)\s+(-?[\d.]+)|path d="M (-?[\d.]+)\s+(-?[\d.]+)/)
  return body unless match
  x = (match[1] || match[3]).to_f.round
  y = (match[2] || match[4]).to_f.round
  [x, y]
end
```

That mixes "data" (the anchor) with "presentation" (the rendered
string), and it parses the same SVG twice. Re-introducing the
anchor as a Ruby value fixes both.

## After

`Markers::Entry` is now a Struct that carries the anchor alongside
the body, with hash/eql? defined so `Array#uniq` collapses by
anchor without touching the SVG:

```ruby
Entry = Struct.new(:style_key, :body, :anchor, keyword_init: true) do
  def hash
    anchor.hash
  end

  def eql?(other)
    other.is_a?(Entry) && anchor == other.anchor
  end
end
```

`entries_for` computes the anchor once when building the Entry:

```ruby
def anchor_for(spec)
  tx, ty = translate_point(spec.anchor)
  [tx.round, ty.round]
end
```

## Benefits

- **Performance**: one anchor computation per marker instead of
  a regex match per dedup pass.
- **Type safety**: anchor is a `[Integer, Integer]` pair, not a
  parsed fragment of a String.
- **Encapsulation**: rendered SVG never re-parsed.
- **Testability**: `Entry#eql?` is unit-testable in isolation.

## Tests

- `spec/ea/svg/ea_emitter/markers_entry_spec.rb` covers anchor
  equality, deduplication, and false-positive guards.

## Bench

Unchanged: rect -221, path -280, polygon -6, text -601,
overlap 64.5%. The refactor is behavior-preserving.
