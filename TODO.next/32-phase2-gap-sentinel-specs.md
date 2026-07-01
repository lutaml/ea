# 32 - Phase 2 sentinel specs (track xmi gem gaps)

## Status: ✅ DONE (2026-07-01) — sentinels flipped as xmi gem schema migrated

## Problem
TODO 21 documented four attribute gaps the xmi gem didn't model.
The original spec suite did not assert the absence of these
attributes. When the xmi gem added support, nothing in the ea test
suite signaled that we should wire them up.

## Original fix (sentinels)
Added sentinel specs that explicitly asserted these attributes were
not emitted, with comments pointing at TODO 21. When the xmi gem
added support, the first PR to wire the attribute up would need to
flip the assertion to positive — making the wiring visible in code
review.

## Update after xmi gem schema migration
The xmi gem refactor branch `refactor/owned-end-schema-gap` landed
schema support for:
- `visibility` on Property / Operation / Parameter / OwnedEnd / Class
- `isAbstract` on packagedElement
- `aggregation` on OwnedEnd
- `classifier` on InstanceSpecification
- `upperValue`/`lowerValue` child models on OwnedEnd (TODO 26)
- `Slot`, `OpaqueExpression`, `InterfaceRealization` new models

The ea transformer was extended to wire up visibility, isAbstract,
aggregation (containment mapping), classifier (pdata1 mapping), and
the OwnedEnd child elements.

## Current spec state
The original "Phase 2 gaps" sentinel block has split into two:

### Phase 2 wiring (xmi gem schema migration landed)
Positive assertions for the four attributes now emitted:
- visibility on Property
- visibility on Operation
- isAbstract on packagedElement
- upperValue/lowerValue on ownedEnd

### Phase 2 gaps still deferred
Negative assertions for two attributes the basic.qea fixture does
not exercise (no data to wire against):
- aggregation on ownedEnd (no composite/shared containment in fixture)
- classifier on InstanceSpecification (no pdata1 set in fixture)

When a fixture with relevant data is available, these flip to positive.

## Verification
All qea_to_xmi specs pass (104 examples). Output now emits visibility
on all 102 attributes, isAbstract on all 65 classes, upperValue and
lowerValue on all 102 attributes + 80 association ends.
