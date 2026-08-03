# TODO-D 36: InstanceSpecification model (full Object diagram support)

## Problem

EA `t_object.Object_Type = 'Object'` rows are UML
InstanceSpecifications. Currently mapped to Klass (the instance
name renders correctly), but EA also shows:

  - The role binding: "Object 01 / roleOne: Class A"
  - The slot compartment: "attributeOne = valueOne" per slot

## Current State

basic.qea text delta: -38. The 4 Object diagrams in basic.qea
have instance names rendered but miss role bindings and slots.

## Implementation Plan

1. Add `Ea::Model::InstanceSpecification < Classifier`:
   - `name` (already inherited)
   - `classifier_ref` (GUID of instantiated Class)
   - `slots` collection of `Ea::Model::Slot {name, value}`

2. Update `t_object.Object_Type = 'Object'` → InstanceSpecification
   in ObjectClassifierMap.

3. Parse the Classifier column from t_object to populate
   `classifier_ref`. Parse t_objectproperties rows owned by
   instance objects as Slot entries.

4. Render header as "InstanceName / roleName: ClassName" when
   classifier_ref + role are set; else just InstanceName.

5. Render slot compartment below the header (italic, like tagged
   values) with "slotName = value" per slot.

## Acceptance

- Object diagrams in basic.qea render all reference texts.
- basic.qea text delta within ±10.
- InstanceSpecification specs cover: bare instance, instance +
  classifier, instance + slots, instance + role + slots.
