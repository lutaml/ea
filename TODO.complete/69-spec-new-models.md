# TODO.complete/69: Specs for newly-added QEA models

## Status: open

The following models were added in TODO 44 / TODO 7 sessions but
have no spec coverage: `EaSecrypt`, `EaPalette`, `EaPaletteItem`,
`EaImplement`, `EaRoleConstraint`, `EaObjectProblem`, `EaObjectRisk`,
`EaObjectTest`, `EaObjectEffort`, `EaObjectResource`,
`EaObjectScenario`, `EaObjectRequire`, `EaObjectTrx`.

Without specs, regressions in column mapping or primary key logic
go undetected.

## Plan

1. Single consolidated spec file: `spec/ea/qea/models/
   auxiliary_models_spec.rb`.
2. Per-model `it "loads primary key and columns"` block.
3. Verifies `primary_key_column` is correct.
4. Verifies `column_map` translates known column names to symbols.

## Acceptance

- File exists, all 13 models have at least 1 example.
- `bundle exec rspec` passes with 0 failures.
