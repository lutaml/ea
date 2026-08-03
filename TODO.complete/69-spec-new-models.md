# TODO.complete/69: Specs for newly-added QEA models

## Status: done

All 13 models listed below have primary_key, table_name, column_map,
and from_db_row coverage in
`spec/ea/qea/models/auxiliary_models_spec.rb` (66 examples, 0
failures).

## Models covered

`EaSecrypt`, `EaPalette`, `EaPaletteItem`, `EaImplement`,
`EaRoleConstraint`, `EaObjectProblem`, `EaObjectRisk`, `EaObjectTest`,
`EaObjectEffort`, `EaObjectResource`, `EaObjectScenario`,
`EaObjectRequire`, `EaObjectTrx`.

## Follow-up

See [[70-specs-for-all-models]] for expanding spec coverage to the
remaining 18 models that currently rely on integration tests only.
