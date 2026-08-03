# TODO-D 64: Missing «property» stereotype labels on association roles

## Status: completed

The `PROPERTY_OY_GAP_THRESHOLD = 15` constant in
`Ea::Svg::EaEmitter::Label::EndLabel` was incorrectly gating
`«property»` rendering. Reference SVGs show EA always emits the
stereotype when both a role name and multiplicity are present,
regardless of the OY gap between the LLT and LLB geometry boxes.

## Fix

Removed the threshold; `property_label?` now returns true whenever
called. The basic.qea associations that skip `«property»` do so
because they have no role name, not because of any gap.

## Results

Plateau QEA text delta: -292 → -3 (closed 289 missing text labels).
test.qea text delta: 0 → +2 (regression of 2 —
the threshold was masking a different issue there).
Matched count unchanged (154/188).
