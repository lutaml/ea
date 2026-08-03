# TODO.complete/44: Remaining QEA tables

## Status: open

Still uncovered tables with real value:

| Table | Purpose |
|---|---|
| t_secrypt | Encryption metadata |
| t_palette | Toolbox definitions |
| t_paletteitem | Toolbox items (stereotype→icon mapping) |
| t_implement | UML→code mapping hints |
| t_roleconstraint | Security/permission roles |
| t_objectproblems | Issue tracking |
| t_objectrisks | Risk register |
| t_objecttests | Test cases |
| t_objecteffort | Effort estimates |
| t_objectresource | Resource allocation |
| t_objectscenarios | Use case scenarios |
| t_objecttrx | Transactions |
| t_objectfiles | Attached files |
| t_objectmetrics | Metrics |
| t_objectrequires | Requirements trace |
| t_scenariotypes | Scenario type enums |
| t_testplans | Test plans |
| t_testclass | Test class definitions |

## Plan

Each table follows the existing pattern:
1. Add `Ea::Qea::Models::EaXxx` model
2. Register autoload in `lib/ea/qea/models.rb`
3. Add to MODEL_CLASSES in DatabaseLoader
4. Add to qea_schema.yml
5. Smoke spec verifying rows load from real fixtures

## Acceptance

- All listed tables have models + load without error.
- `ea stats` shows the new counts.
