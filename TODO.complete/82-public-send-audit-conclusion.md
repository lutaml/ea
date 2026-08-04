# TODO.complete/82: public_send audit conclusion

## Status: done (no action needed)

Audited all 34 `public_send` sites in lib code. Conclusion: all are
legitimate dynamic dispatch on public methods. None call private
methods. The user's rule ("No `send` on private methods") is
satisfied.

## Categorisation

| Category | Sites | Why it's legitimate |
|----------|-------|---------------------|
| `xmi/parser.rb` | 12 | Calls public xmi gem model methods by XML element name. Deferred per TODO 53 (needs upstream wrapper). |
| `base_repository.rb` | 6 | Repository pattern: queries by attribute symbol (`find_by_key`, `where`, `pluck`, `group_by`, `sort_by`). Attribute names come from callers. |
| `base_validator.rb` | 3 | Generic validator across table types: ID/name column names are dynamic per table. |
| `ocl/evaluator.rb` | 3 | OCL expressions reference attributes by name. VarBinding override is core OCL pattern. |
| `validation_engine.rb` | 2 | Collection method lookup by name on Lutaml::Uml::Document. |
| `comparator.rb` | 2 | PK and label attribute lookup (dynamic per model class). |
| `factory/*.rb` | 3 | UML collection accessor by name (`package.classes`, `package.enums`). |
| `database.rb` | 1 | `build_group_index` indexes any collection by any attribute method. |
| `base_model.rb` | 1 | `primary_key` calls the PK column getter (dynamic per model). |

All sites use `public_send` (not bare `send`), which only resolves
public methods. No encapsulation violation.
