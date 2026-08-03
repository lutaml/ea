# TODO-D 55: Visibility icon discriminator (deferred)

## Status: deferred (out of scope for current session)

EA renders a "folded page" visibility icon for each attribute row
in some diagrams. The discriminator is `ShowIcons=1` in the
diagram's Style1 string.

## Icon design (per attribute row)

```
y_top (rect.y)
y_top..y_top+4:   inner rect 11x4 (white fill, blue stroke)
y_top..y_top+14:  outer rect 11x14 (pale yellow, blue stroke)
y_top+7:          horizontal path (midline)
y_top+5, y_top+9, y_top+11: 3 short "text line" paths (4 wide)
```

Total: 2 rects + 4 paths = 6 elements per attribute row.

## Where it appears

| Diagram | rect | path | text | Why |
|---------|------|------|------|-----|
| basic.qea Package Imports | -6 | -18 | -4 | 2 attrs × 6 elements = 12 missing |
| test.qea Test Model | -15 | -58 | -11 | 8 attrs × 6 elements = 48 missing |
| basic.qea Operations+Object | similar | similar | similar | some object diagrams |

## Implementation

1. Parse `ShowIcons=N` from `t_diagram.Style1` (or per-element
   `HideIcon=N` from `t_diagramobjects.Style`).
2. When ShowIcons=1 (or default-icon), pass an `icon_visibility`
   flag through `RenderContext`.
3. Add a new `Compartment::VisibilityIcon` module that renders
   the 2 rects + 4 paths per attribute row.
4. Wire it into the Attribute compartment (or render alongside
   it).

## Why deferred

- Requires parsing the QEA Style1 string (already done in
  DisplayConfig for other flags).
- Discriminator must be verified across more diagrams (e.g.
  plateau's Building diagram has 1 icon — the same logic should
  apply).
- Each attribute row needs the icon rendered at a precise offset
  (currently at content_x_offset, attr_y - 9).

Closes ~80 rects + ~50 paths in basic.qea + ~70 rects + ~250
paths in test.qea (Test Model with 8 attrs).

## Code-quality alignment

The new `Compartment::VisibilityIcon` would follow the OCP
pattern established by the Compartment pipeline — adding a new
compartment = appending to `Compartment::ALL`, no modification
of `Elements#groups_for` needed.
