# TODO.complete/03: t_objectproperties + t_objectconstraint parsing

## Status: done

Two EA tables we currently ignore. Both carry modeling metadata that maps
to UML2 concepts:

| Table | UML2 concept | Example |
|---|---|---|
| t_objectproperties | applied stereotype property values | `targetNamespace=http://...`, `xsdDocument=test.xsd` |
| t_objectconstraint | Constraint / invariant | OCL: `inv: self.string->exists(...)` |

## Volume observed

| QEA | t_objectproperties | t_objectconstraint |
|---|---|---|
| basic | 0 | 0 |
| test | 44 | 1 |
| plateau v5.1 | 1537 | 4 |

## Plan

1. Add `Ea::Model::ObjectProperty` (or reuse `TaggedValue`) — EA's
   t_objectproperties is functionally identical to applied-stereotype
   properties. Decide: model as tagged values OR as distinct entity?
   - **Decision**: model as `TaggedValue` (already exists) since EA
     semantically treats these as stereotype property applications. The
     distinction is storage, not semantics.
2. Add `Ea::Model::Constraint` (already exists per `lib/ea/model/constraint.rb`).
3. Add `Ea::Qea::Models::EaObjectProperty` and `EaObjectConstraint` raw-row models.
4. Wire into `DatabaseLoader` + `Database` collections.
5. `ClassifierBuilder` attaches both to the classifier.
6. Constraint rendering: a new compartment below operations showing
   `{constraint_name}: OCL expression`.

## Schema (from plateau v5.1)

```sql
-- t_objectproperties
Property TEXT, Value TEXT, Notes TEXT, ea_guid TEXT, Object_ID INTEGER, ...

-- t_objectconstraint
Constraint TEXT, ConstraintType TEXT, OCL, Notes, ea_guid, Object_ID
```

## OCP / MECE

- Raw-row model per table (MECE: each table = one model).
- Transformation to UML concept lives in the bridge (ClassifierBuilder).
- Constraint rendering is a new compartment module.

## Acceptance

- Spec: `Ea.parse(test_qea).classifiers.find(...).constraints.first.name == "pattern"`.
- Spec: `Ea.parse(test_qea).classifiers.find(...).tagged_values` includes
  `targetNamespace` property.
- Spec: plateau v5.1 parses 1537 properties without error.
