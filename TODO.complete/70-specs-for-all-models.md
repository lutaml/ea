# TODO.complete/70: Specs for all remaining QEA models

## Status: done

Added consolidated spec coverage for the 18 remaining QEA models
that had no dedicated specs. Each model gets `table_name`,
`primary_key_column`, and `from_db_row` coverage.

## Models covered

`EaAttributeTag`, `EaAuthor`, `EaComplexityType`, `EaConnectorType`,
`EaConstraintType`, `EaDatatype`, `EaDiagramLink`,
`EaDiagramObject`, `EaDiagramType`, `EaGlossary`, `EaImage`,
`EaList`, `EaObjectProperty`, `EaObjectType`, `EaPhase`,
`EaStatusType`, `EaStereotype`, `EaTaggedValue`, `EaVersion`.

## Implementation

Spec file: `spec/ea/qea/models/all_models_spec.rb`. Uses the same
consolidated pattern as `auxiliary_models_spec.rb` — one shared
example per model, parameterized by expected table/pk.
