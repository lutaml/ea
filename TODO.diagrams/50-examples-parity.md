# TODO-D 50: Examples (basic, simple, test, etc.) parity

## Goal

Get every example QEA in `examples/qea/` matching its reference
SVGs in `examples/exports/<name>/images/`.

## Current bench (`rake svg:examples`)

| Example | Matched | rect | path | polygon | text |
|---------|---------|------|------|---------|------|
| simple  | 2/2     | 0    | 0    | 0       | 0    |
| ArcGISWorkspace_template | 5/6 | -2 | -7 | 0 | -1 |
| basic   | 19/22   | -3   | -30  | -6      | -22  |
| test    | 1/2     | -15  | -58  | 0       | -11  |

**simple.qea is at 100%!** Zero deltas across the board.

## Architecture addition

`rake svg:examples` benches every QEA in `examples/qea/` against
its matching `examples/exports/<name>/{images,Images}/` directory.
Run after every renderer change to catch regressions in any
example.

## Remaining per-example deltas

### test.qea — Test Model diagram (-15 rect, -58 path, -11 text)

1 element (Package "Test Schema") + 0 connectors. Reference has
16 small visibility-marker rects at x=40 (one per attribute row)
+ 8 horizontal divider paths inside the markers. Each attribute
row in this diagram shows:
  - 11x14 outer rect (pale yellow, blue stroke)
  - 11x4 inner rect (white)
  - 1 horizontal divider path

That's 3 elements per attribute row × 8 rows = 24 missing
elements. Plus the Package tab icon path. Total ~25 missing.

### basic.qea — visibility icons + object instance format

Top outliers:
- Package Imports (-6 rect, -18 path): visibility icons +
  package-tab icons.
- Object with Value Specifications (-6 path, -19 text): Object
  instance rendering. EA shows "Object 01 / roleOne: Class A" and
  "attribute = value" slot format. We render the qualified class
  name only.
- Objects as Instances of Classes (-4 path, -9 text): same Object
  instance format issue.

## Discriminator for visibility icons

Visibility icons appear in:
- Test Model (test.qea) — Package element with attribute rows
- Package Imports (basic.qea) — visibility column next to attrs

They do NOT appear in:
- simple.qea — no attribute compartments shown
- Most basic.qea class diagrams — already have +/- text markers

The discriminator is likely:
- Diagram style1 flag (HideProps=0 + VisibleAttributeDetail=1)
- OR element-level ShowIcon-style flag

## Acceptance

- Implement VisibilityIconRenderer (per-attribute 3-element
  decoration).
- Implement ObjectInstance rendering format.
- Bench each example QEA → 0/0/0/0 deltas.

## Verification

`rake svg:examples` runs all example benchmarks in one command.
Output format:

```
name                                     N/M matched
  rect    ours=X ref=Y delta=Z (Z%)
  path    ...
  polygon ...
  text    ...
```
