# TODO-D 72: Spurious per-attribute divider paths on basic.qea outlier

## Status: open

basic.qea diagram "Two Level Class Composition Hierarchy with
Attributes" (4FC1D352-...) over-renders 16 short horizontal <path>
elements that the EA reference does not emit.

## Symptom

  - rect:  ours=18  ref=18  (matches)
  - path:  ours=50  ref=34  (+16 overshoot)
  - polygon: ours=17 ref=17 (matches)
  - text:  ours=102 ref=102 (matches)

## Pattern of the extra paths

All 16 extras are short 110px-wide horizontal lines at evenly
spaced y coordinates that line up with attribute rows:

  - M 661 66 L 771 66
  - M 661 152 L 771 152
  - M 661 238 L 771 238
  - M 487 66 L 597 66
  - M 487 152 L 597 152
  - ... (12 more at the same y values across 4 element columns)

## Hypothesis

We render per-attribute separator lines between each attribute row.
EA only emits a single header→content divider plus the element rect
outline; attribute rows are NOT visually separated by horizontal
lines in EA's encoding.

## Next step

Audit Compartment::Attributes and DividerRenderer for any per-row
line emission. The fix is to suppress row separators and keep only
the header divider.
