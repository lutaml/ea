# TODO.complete/61: PlantUML export — relationships + packages

## Status: done

Current `Ea::Export::PlantUml::Generator` only emits classes +
their attributes. Doesn't emit:
- Package nesting (`package "X" { ... }`)
- Generalizations (`Parent <|-- Child`)
- Associations with multiplicity (`A "1" --> "0..*" B : name`)

## Plan

1. Wrap classes in their containing package blocks.
2. Emit generalization arrows from `connectors` where
   `connector_type == "Generalization"`.
3. Emit associations with source/target multiplicities and role names.

## Acceptance

- Spec: PlantUML output for a 2-class model with one generalization
  contains `Parent <|-- Child`.
- Spec: classes are nested in `package "X" { ... }` blocks.
