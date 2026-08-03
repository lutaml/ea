# TODO-D 24: Track marker anchors structurally

## Problem

`Ea::Svg::EaEmitter::Markers#anchor_key` parses the SVG string the
class itself just emitted in order to deduplicate entries by their
anchor point:

```ruby
def anchor_key(body)
  match = body.match(/polygon points="(-?[\d.]+)\s+(-?[\d.]+)|path d="M (-?[\d.]+)\s+(-?[\d.]+)/)
  return body unless match
  ...
end
```

This is fragile:

- Round-trip through string parsing for data we already had
  structurally.
- Regex assumes EA's exact SVG attribute ordering and whitespace.
- Hard to test in isolation (must build the body string first).

## Fix

Add `anchor` to the `Entry` struct. Capture it when the entry is
built (we already have `tip` at that point). Dedup on
`Entry#anchor` rather than re-parsing the body.

## Acceptance

- `Entry` struct carries `[x, y]` anchor.
- `anchor_key` method removed; dedup uses `Entry#anchor` directly.
- Markers specs continue to pass.
- Parity polygon delta unchanged.
