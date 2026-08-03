# TODO-D 37: Element header icon decorations (test.qea path gap)

## Problem

test.qea has 69 reference paths but we render only 11. The
missing 58 paths are small line segments forming per-element-type
icons inside each attribute / operation row.

Reference example (Test Model diagram, 1 element "Test Schema"):

```
M 40 87 L 50 87     # 10px horizontal stroke (icon body)
M 42 85 L 46 85     # 4px stroke above (icon decoration)
M 48 85 L 49 85     # 1px stroke (icon decoration)
M 42 89 L 46 89     # 4px stroke below
M 48 89 L 49 89     # 1px stroke below
```

The 5-path pattern repeats every 16px (one row per attribute /
operation / tagged-value).

## Cause

EA renders a small icon next to each row in attribute / operation
compartments when the per-element `HideIcon=0` flag is set in
ObjectStyle. The icon shape varies by row kind (attribute gets
one icon, operation gets another, tagged value gets a third).

## Status

Deferred. Reverse-engineering each icon's exact path coordinates
requires EA.exe disassembly or empirical SVG byte-diff for each
icon kind.

## Acceptance (when picked up)

- Identify each icon shape (attribute icon, operation icon, etc.).
- Add Element::RowIcon renderer with a registry by row kind.
- Wire into AttributeRenderer, OperationRenderer, TaggedValueRenderer.
- Specs cover each icon kind with reference-SVG byte match.
- test.qea path delta within ±20 (currently -58).
