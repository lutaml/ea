# TODO-D 57: InstanceSpecification model + slot rendering

## Status: open (blocks 3 basic.qea diagrams + plateau)

EA stores UML InstanceSpecifications in `t_object` rows with
`Object_Type="Object"`. Currently we parse these as `Klass`
instances (the closest classifier shape). Ref renders them as
instances with three features we don't emit:

1. **Instance label format** in the header: `instance_name` plus,
   when the instance is a role in an association, the role +
   classifier name (e.g. `"Object 01 / roleOne: Class A"`).
2. **Slot compartment** below the header: each `RunState` variable
   is rendered as `"variable = value"` (e.g.
   `"attributeOne = valueOne"`).
3. **From-package subtitle** below the slots:
   `"(from Objects)"` — the containing package name in italics.

## Affected diagrams

| Diagram | text_delta | Notes |
|---------|-----------|-------|
| Basic Object Diagram with Value Specification | -2 | 1 slot per instance |
| Objects as Instances of Classes | -9 | 1 instance label + slot + from-package per box |
| Object with Value Specifications | -19 | 1 instance label + multiple slots + from-package per box |

Plus widespread contribution to the plateau text delta (-615).

## Source data

`t_object` columns for Object instances:
- `Object_Type="Object"`
- `Name="Object 01"` (the instance name)
- `Classifier=<id>` (the class this is an instance of; 0 = none)
- `RunState="@VAR;Variable=X;Value=Y;Op==;@ENDVAR;..."` (slots)

The role name (`"roleOne"`) comes from the connector's source role
field on the association linking this instance to another.

## Implementation plan

### 1. Model

- `Ea::Model::InstanceSpecification < Base` — new model class
  - `name :string`
  - `classifier_id :string` (id of the class this is an instance of)
  - `slots :Slot, collection: true`
  - `role_name :string` (filled in later by relationship resolver)
  - `package_id :string`
  - `qualified_name :string`
- `Ea::Model::Slot < Base` — a slot value
  - `name :string` (the variable)
  - `value :string`
  - `op :string` (default `"="`)

### 2. Source side

- `Ea::Sources::Qea::InstanceBuilder` — new builder that reads
  `t_object` rows where `Object_Type="Object"` and parses `RunState`
  into Slot instances. Replaces the `Object → Klass` mapping in
  `ObjectClassifierMap`.
- Update `Ea::Sources::Qea::Adapter` to call both `ClassifierBuilder`
  and `InstanceBuilder`.
- Update `Document#index_by_id` to include instance specifications.

### 3. Render side

- `Compartment::InstanceHeader` (new) — renders the instance label
  format `name / role: ClassName` in the header.
- `Compartment::InstanceSlots` (new) — renders the slot compartment
  (`variable = value` lines).
- `Compartment::InstanceFromPackage` (new) — renders the
  `"(from packageName)"` subtitle in italics.
- The existing `InstanceUnderline` module is reused for the
  instance-name underline.
- `Shape` compartment: dispatch instance specs to a new
  `InstanceShapeRenderer` (or reuse `ShapeRenderer` since the box
  shape is the same).

### 4. Specs

- Instance model spec (round-trip JSON)
- InstanceBuilder spec (parses RunState correctly)
- InstanceSlots spec (renders "var = value")
- InstanceFromPackage spec (renders italic "(from X)")

## Discriminator

When `diagram.diagram_type == "Object"` AND `model_element.is_a?(InstanceSpecification)`:
- Header: instance label format
- Body: slot compartment + from-package subtitle

Otherwise: standard classifier rendering.

## Why deferred initially

Requires a new top-level model class, source-builder wiring, and 3
new compartments. ~300 lines of code + ~150 lines of specs. Affects
the parity metric broadly (basic.qea +3 diagrams strict-perfect,
plateau text delta improves).
