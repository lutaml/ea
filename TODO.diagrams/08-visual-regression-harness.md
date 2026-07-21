# 08 - Visual Regression Harness

## Status: TODO (follow-up after 01-07 land)

## Problem

"Matches EA's SVG" is a fuzzy target. We need an automated way to
detect regressions and measure fidelity.

## Approach

A spec that:

1. Loads `plateau_all_packages_export.xmi`.
2. For each diagram in the XMI's extension block, locates the
   matching EA reference SVG in
   `mn-samples-plateau/sources/001-mds/xmi-images/`.
3. Renders our SVG for the same diagram.
4. Compares structurally (canonicalized XML diff ignoring
   whitespace and attribute order).
5. Reports: which diagrams match exactly, which have structural
   differences, which have only attribute differences.

Not a hard-fail spec; produces a report we can track over time.
Once fidelity is high enough, tighten to a hard threshold.

## Files

- `spec/ea/svg/visual_regression_spec.rb`
- `spec/support/svg_canonicalizer.rb`

## Verification

- Run produces a report; not asserting 100% match initially.
