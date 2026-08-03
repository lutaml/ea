# Examples parity report (2026-07-28)

`rake svg:examples` benches every QEA in `examples/qea/` against
its matching exports/Images directory.

## Headline

| Example | Matched | Perfect | Notes |
|---------|---------|---------|-------|
| simple  | 2/2     | **2**   | 100% parity |
| ArcGISWorkspace_template | 5/6 | 5 | Workspace diagram has decorative icons |
| basic   | 19/22   | 8       | Visibility icons + Object instance format missing |
| test    | 1/2     | 1       | Test Model diagram needs visibility icons |

**15 of 27 renderable example diagrams are at 100% parity.**

## Per-example breakdown

### simple.qea — 100% ✓

```
simple  2/2 matched
  rect    ours=8  ref=8  delta=0
  path    ours=3  ref=3  delta=0
  polygon ours=12 ref=12 delta=0
  text    ours=22 ref=22 delta=0
```

Both diagrams (`Simple Package Diagram`, `Simple Class Diagram`)
render byte-identical element counts.

### ArcGISWorkspace_template — 5/6 perfect

Only `ArcGIS Workspace` diagram has deltas (-2 rect, -7 path).
The 7 missing paths are decorative "data icon" paths (small
horizontal lines + dots) inside one element's attribute
compartment. Canvas height calc is also slightly off (641 vs 600).

### basic.qea — 8/22 perfect, 19/22 within tolerance

**Perfect diagrams:**
- Package Contents
- Package Dependencies
- Package B
- Basic Class Diagram with Multiplicities
- Signals
- Two Level Class Type Hierarchy with Attributes
- Two Level Class Composition Hierarchy with Attributes
- Composition with Substitution

**Remaining gaps (concentrated in 3 areas):**

1. **Visibility icons** (Test Model diagram in test.qea +
   Package Imports + Object with Value Specifications in basic):
   EA renders 3 elements per attribute row (outer rect 11x14 +
   inner rect 11x4 + horizontal divider path). Implementing this
   would close ~25 rects and ~15 paths across examples.

2. **Object instance format** (Objects as Instances of Classes +
   Object with Value Specifications): EA renders
   `Object 01 / roleOne: Class A` and `attribute = value` slot
   format. We render the qualified class name only.

3. **Decorative data icons** (ArcGIS Workspace): "Hamburger menu"
   icons (3 horizontal lines + dots). Specific to ArcGIS template.

### test.qea — 1/2 perfect

- `TestSchema` diagram: 100%
- `Test Model` diagram: needs visibility icons + Package element
  attribute rendering

## How to run

```
bundle exec rake svg:examples
```

Outputs per-example bench in a single table. Run after every
renderer change to catch regressions in any example.

## Architecture

The `rake svg:examples` task auto-discovers QEA files in
`examples/qea/` and matches them with ref directories in
`examples/exports/<name>/{images,Images}/`. Uses the existing
`Ea::Svg::Parity::Suite` with `Ea::Sources::Qea::IdNormalizer`
for diagram-id → SVG-filename resolution.
