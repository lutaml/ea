# 35 - Walk t_object.RunState for instance specification slots

## Status: FUTURE — requires EA internal format investigation

## Problem
The `build_instance` method in
`lib/ea/transformers/qea_to_xmi/transformer.rb` currently emits an
empty `slot: []` array:

```ruby
def slots_for(obj)
  []
end
```

This is correct for `Object` rows that have no run-state, but
silently drops the run-state data that real Sparx XMI carries as
`<slot>` children of `<packagedElement type="uml:InstanceSpecification">`.

EA stores run-state in `t_object.RunState` as a serialized XML blob:

```xml
<runstate>
  <scxml scdatamodel="...">
    <state id="...">
      <onentry>...</onentry>
    </state>
  </scxml>
</runstate>
```

Or, for instance specifications of class-typed objects, EA stores
attribute values in `t_attribute` rows that reference the instance
via `ea_object_id`. The transformer's `attributes_for(obj)` already
handles these for Property emission on classifiers; the same rows
need a different shape (Slot + ValueSpecification) when the parent
is an InstanceSpecification.

## Proposed shape

### Step 1: detect instance-specification attribute rows
Add `Ea::Qea::Models::EaAttribute#instance_value?` (or check
`object_type == "Object"` on the parent) to distinguish:
- Classifier attribute (Property with `<upperValue>` etc.)
- Instance-specification slot (Slot with `<value>` children)

### Step 2: build Slot with polymorphic ValueSpecification
For instance-specification attribute rows, emit:

```ruby
::Xmi::Uml::Slot.new(
  type: "uml:Slot",
  id: @context.id_allocator.allocate(prefix: IdAllocator::SLOT, seed: "slot-#{attr.id}", parent_guid: parent.ea_guid),
  defining_feature: @context.xmi_id_for(classifier_attr),
  value: [build_value_specification(attr)],
)
```

Where `build_value_specification` dispatches on the EA type:

| EA type          | ValueSpecification subclass      |
|------------------|----------------------------------|
| String / default | `OpaqueExpression` with `body`   |
| Integer          | `LiteralInteger`                 |
| Boolean          | `LiteralBoolean`                 |
| Real             | `LiteralString` (no LiteralReal) |
| null             | `LiteralNull`                    |

### Step 3: spec coverage
Use the `sparx-instance-specification.xmi` fixture from the xmi gem
(or a real EA export when one is acquired — see xmi/TODO.next/03)
to assert the transformer's output matches the expected slot/value
shape.

## Why deferred

- The current `basic.qea` fixture has no InstanceSpecification rows
  with RunState data, so there is no test data to drive the wiring.
- EA's RunState format is a serialized XML blob that needs its own
  parser (similar to how `t_object.Style` is parsed for diagram
  rendering).
- Acquiring a real Sparx export with instance specifications is a
  prerequisite (see xmi/TODO.next/03 — "Real Sparx
  InstanceSpecification fixture").

## Verification (when implemented)
- New spec: instance specification with one attribute emits one
  `<slot>` child with one `<value>` of the right polymorphic type.
- Round-trip via `Xmi::Sparx::Root.parse_xml` preserves the slot
  values.
- The `slots_for(obj)` stub is replaced with real walk logic.
