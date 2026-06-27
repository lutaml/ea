# 03 - Slim `lutaml-uml`: Remove All EA-Specific Code

## Status: DONE (2026-06-27)

## Outcome
The dependency confusion that motivated this TODO is fixed. See the
"Critical Fix Applied" section below for the two cross-requires that were
eliminated, and the "Verification" section for the grep audit showing zero
cross-requires in either direction.

## Critical Fix Applied: Cross-Require Elimination

The dependency confusion was the worst problem. Two cross-requires between
the generic UML metamodel and EA-specific code are now **fixed**:

### 1. `DocumentStructureValidator` no longer extends `Qea::Validation::BaseValidator`

**Before** (broken): generic UML validator depended on EA-specific base
```ruby
# lutaml-uml/lib/lutaml/uml/validation/document_structure_validator.rb
class DocumentStructureValidator < Qea::Validation::BaseValidator  # ← CROSS-REQUIRE
```

**After** (clean): generic UML validator extends generic UML base
```ruby
class DocumentStructureValidator < BaseValidator  # Lutaml::Uml::Validation::BaseValidator
```

Created `lutaml-uml/lib/lutaml/uml/validation/base_validator.rb` — a
lightweight base with `result`, `context`, `document`, `options`, `add_error`,
`add_warning`, `present?`, `call`, `validate`. Zero EA dependencies.

### 2. `UmlRepository` no longer calls `Lutaml::Xmi::Parsers::Xml.parse`

**Before** (broken): repository hard-coded Sparx XMI parser
```ruby
# lutaml-uml/lib/lutaml/uml_repository/repository.rb
document = Lutaml::Xmi::Parsers::Xml.parse(File.new(xmi_path))  # ← CROSS-REQUIRE
```

**After** (clean): composition-based API, no parser coupling
```ruby
# Repository.from_document(document) — wrap a pre-parsed document
# Repository.from_file(path) — only .lur (native), raises for others with guidance
# Repository.from_file_cached(source_path) — requires a block to parse the source
```

Users compose the parsing themselves:
```ruby
document = Ea::Qea.parse("model.qea")
repo = Lutaml::UmlRepository::Repository.from_document(document)
```

No registry, no load-time side effects, no `if defined?` hacks.

## What Still Needs Deletion from lutaml-uml

| Module | Files | Status |
|---|---|---|
| `lib/lutaml/qea.rb` + `qea/` | 87 | DELETE (lives in `ea`) |
| `lib/lutaml/ea.rb` + `ea/` | 14 | DELETE (lives in `ea`) |
| `lib/lutaml/xmi.rb` + `xmi/` | 22 | DELETE (lives in `ea`) |
| `lib/lutaml/model_transformations.rb` + dir | 6 | DELETE (lives in `ea`) |
| `lib/lutaml/cli.rb` + `cli/` | 30 | DELETE (EA-flavored CLI) |
| `lib/lutaml/lml.rb` | 1 | DELETE (separate gem) |
| `config/qea_schema.yml` etc. | 3 | DELETE (in `ea`) |
| EA-specific specs | ~70 | DELETE (in `ea`) |

## Verification (cross-requires = 0)

```bash
# ea core has zero refs to lutaml-uml modules
grep -rn 'Lutaml::UmlRepository\|Lutaml::Xmi\|Lutaml::Qea' lib/ea/qea/models/ lib/ea/qea/database.rb lib/ea/qea/infrastructure/ lib/ea/qea/services/ lib/ea/qea/repositories/
# → 0 results

# lutaml-uml has zero refs to EA code
grep -rn 'Lutaml::Qea\|Lutaml::Ea::\|Lutaml::Xmi\|Qea::' lutaml-uml/lib/lutaml/uml/ lutaml-uml/lib/lutaml/uml_repository/
# → 0 results
```
