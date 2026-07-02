# 35 - Walk t_object.RunState for instance specification slots

## Status: ✅ DONE (2026-07-03)

## Problem
`build_instance` originally emitted an empty `slot: []` array, which
silently dropped the run-state data that real Sparx XMI carries as
`<slot>` children of `<packagedElement type="uml:InstanceSpecification">`.

EA serialises run-state in `t_object.RunState` as a delimited string:

```
@VAR;Variable=<name>;Value=<value>;Op=<op>;@ENDVAR;
```

Multiple `@VAR` blocks concatenate directly. Each block maps to one
UML Slot.

## Fix

### RunState module
`lib/ea/transformers/qea_to_xmi/run_state.rb` is a pure-function
parser. Returns an array of `Binding` structs (`Struct.new(:variable,
:value, :op)`). The `Binding#body` method renders the Sparx wire form
(`Op==` + `Value=Alice` → `body="=Alice"`).

### Transformer wiring
- `slots_for(obj)` walks `RunState.parse(obj.runstate)` and emits one
  `Xmi::Uml::Slot` per binding.
- `build_slot(instance, binding)` constructs the Slot with:
  - `xmi:id` from `IdAllocator.allocate(prefix: SLOT, ...)`
  - `definingFeature` resolved by looking up the named attribute on
    the instance's classifier (via `t_object.classifier`)
  - one `OpaqueExpression` value carrying the body
- `build_slot_value` builds the OpaqueExpression with `xmi:id` from
  `IdAllocator.allocate(prefix: OPAQUE_EXPRESSION, ...)`.
- `defining_feature_for(instance, binding)` looks up the classifier
  via `obj.classifier.to_i` (NOT `pdata1` as originally documented —
  the live `t_object.classifier` column holds the ea_object_id of
  the classifier directly).

### ID prefixes used
Both `SLOT` (`"SL"`) and `OPAQUE_EXPRESSION` (`"OE"`) are already on
`IdAllocator`'s well-known-prefix list — no constant additions.

## Discovery: t_object.classifier column
The original TODO 35 draft assumed `pdata1` held the classifier ID.
Investigation during implementation showed:

- `pdata1`: always `nil` for `Object`-type rows in basic.qea.
- `classifier`: an Integer column holding the classifier's
  `ea_object_id` directly. Zero when no classifier is set.

This matches what real Sparx XMI emits: InstanceSpecification rows
without a classifier have no `classifier="..."` attribute on the
`<packagedElement>`; rows with a classifier do.

## Verification
- Output for basic.qea: 22 slots, 20 with `definingFeature` (the 2
  without come from InstanceSpecifications that have no classifier).
  This matches the reference `spec/fixtures/basic.xmi` exactly.
- Each slot carries one `<value>` child typed as
  `uml:OpaqueExpression` with `body="=Value..."`.
- Slot IDs use the Sparx `EAID_SL<NN>__<guid>` format; OpaqueExpression
  IDs use `EAID_OE<NN>__<guid>`.
- RunState module specs: 13 examples, 0 failures (pure-function
  parser, edge cases covered).
- Slot emission specs in transformer_spec.rb: 4 new examples
  asserting count, body shape, definingFeature presence, ID prefix.

## Sentinel flipped
The "Phase 2 gaps still deferred" sentinel block had a negative
assertion for `classifier on InstanceSpecification`. With this
wiring landed, the spec flipped to a positive assertion. The
`aggregation on ownedEnd` sentinel remains negative (basic.qea
carries no composite/shared containment examples).
