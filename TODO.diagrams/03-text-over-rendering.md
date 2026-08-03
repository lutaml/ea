# TODO-D 03 - Text over-rendering

## Status: COMPLETE (2026-07-26)

## Root cause

The tagged values compartment was rendered unconditionally for
every classifier that had tagged values, regardless of the
diagram's actual display configuration. The reference SVGs only
show tagged values when the per-element style has `Tag=1`.

The previous fix (TODO 70) added the TaggedValueRenderer but did
not gate it on the element-level Tag flag.

## Fix

`Elements#groups_for` now reads `element.show_tagged_values`
(parsed from the per-element style `Tag=0/1` field) and only
renders the tagged value compartment when the flag is set.

The `DiagramElement` model gained `show_tagged_values` boolean.
`ExtensionStyleParser` populates it from the `Tag=` style key.
`DiagramBuilder` passes it through to the model.

## Impact (full plateau measurement)

| Metric | Before | After |
|---|---|---|
| Text delta vs ref | +5134 (29% over) | -252 (parity) |
| Text overlap avg | 57% | 62% |
