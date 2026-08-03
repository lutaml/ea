# TODO-D 65: Path coordinate frame mismatch (y-axis sign)

## Status: open

Elements render at the wrong vertical position because
`bounds_from_rect` interprets `RectTop` as the math-convention
y (negative, larger=lower) when EA actually stores it as the
negation of the screen-space y (negative, larger=higher).

The bench's shape_delta_total doesn't catch this because counts
match — but per-path coordinate comparison shows every ref path
is "missing" from our output (coordinate values differ).

## Evidence (plateau QEA, "Bridge" diagram)

Raw EA rect for `_CityObject`:
- RectLeft=611, RectTop=-64, RectRight=941, RectBottom=-186

Reference SVG renders `_CityObject` text at `y=73`.

Our model produces `bounds.y = -186` (taking `min(RectTop, RectBottom)`).
After canvas translation we render at `y > 1000` (bottom of canvas).

The correct interpretation is:
- screen-y of element's top edge = `-RectTop = 64`
- height = `RectTop - RectBottom = -64 - (-186) = 122`

With a small offset (33 in basic.qea, 9 in plateau Bridge) we'd
match the reference's text baseline.

## Approach

Update `DiagramBuilder#bounds_from_rect`:

```ruby
def bounds_from_rect(obj_row)
  left = obj_row.rectleft || 0
  right = obj_row.rectright || 0
  top = obj_row.recttop || 0
  bottom = obj_row.rectbottom || 0
  Ea::Model::Bounds.new(
    x: [left, right].min,
    y: -[top, bottom].max,  # flip y-axis
    width: (right - left).abs,
    height: (bottom - top).abs
  )
end
```

Then rework `Canvas#translate_y` and `BoundsCalculator` to use
positive y values consistently. The current min_y computation
also needs to flip.

This is a large change — needs careful re-verification against
basic.qea and test.qea to avoid regressing the 24/24 currently
matched.

## Impact

Doesn't change counts (and so won't move the bench needle), but
makes the visual output match EA positionally. Required before
we can claim "100% identical to QEA->SVG" in any visual sense.
