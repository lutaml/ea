# 34 - Document member-end order + harmonise RT prefix

## Status: DONE (2026-07-01)

## Problem
Two small clarity issues in `lib/ea/transformers/qea_to_xmi/transformer.rb`:

1. **Implicit member-end order.** `build_association` (line 314-324)
   emits `dest_end` first, then `src_end`. EA round-trip depends on
   this ordering but no comment explains why. A future contributor
   re-ordering for "tidiness" would silently break round-trip
   fidelity.
2. **Undocumented "RT" prefix.** `build_return_parameter` (line 400)
   synthesises IDs with `prefix: "RT"`. The `IdAllocator` documents
   well-known Sparx prefixes (LI, OE, SL, NL, DB) but not RT.

## Fix

1. Add a one-line comment at the member-end ordering site explaining
   the Sparx convention. The ordering comes from how Sparx EA
   serialises its `t_connector` rows: destination role first in
   `<memberEnd>`, source role second.
2. Add `RETURN_PARAMETER = "RT"` to IdAllocator's well-known prefix
   list with a comment explaining what it stands for. Update
   `build_return_parameter` to reference the constant.

## Verification
- Diff shows the comment + constant addition; no behaviour change.
- Existing specs continue to pass.
