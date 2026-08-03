# 72 - Use Sample Exports as Regression Specs

## Status: COMPLETE (2026-07-26)

## What changed

`spec/ea/svg/sample_exports_regression_spec.rb` (NEW) — renders
every diagram from `examples/exports/*/model.xml` (220 diagrams
across 5 sample projects) and compares total shape counts
(rect + polygon + path) against the corresponding reference SVG
in `examples/exports/*/images/`.

Two specs:
1. "matches reference element counts within tolerance for most
   diagrams" — asserts at least 60% of diagrams are within 20%
   (or 5, whichever is larger) of the reference total.
2. "renders every diagram without raising" — runs the emitter on
   every diagram and asserts no exceptions.

## Current parity (measured by this spec)

- 178/220 diagrams within tolerance (81%)
- 42 diagrams over tolerance (mostly plateau diagrams with 6-18
  element delta)

## Why combined rect+polygon+path

EA swaps rect↔polygon based on shape type (Classifier=rect,
Package=polygon). Comparing each shape count independently would
double-penalize shape-type swaps that are actually correct. The
combined total reflects "did we emit the right number of shapes?"

## Acceptance

- Spec covers all 220 sample diagrams.
- Passes at >60% threshold (currently 81%).
- Reports first 5 failures when threshold not met.
