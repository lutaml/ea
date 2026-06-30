# 02 - Make `lutaml-uml` an Optional Dependency

## Status: ✅ DONE

## What was implemented

### 1. Removed `require "lutaml/uml"` from `lib/ea.rb`
The core parser loads standalone. Verified: `lutaml/uml.rb` is NOT in
`$LOADED_FEATURES` after `require "ea"`.

### 2. Split the public API (`lib/ea/qea.rb`)

| Method | Requires lutaml-uml? | Returns |
|---|---|---|
| `Ea::Qea.load(path)` | No | `Ea::Qea::Database` (standalone) |
| `Ea::Qea.load_database(path)` | No | `Ea::Qea::Database` |
| `Ea::Qea.connect(path)` | No | `DatabaseConnection` |
| `Ea::Qea.schema_info(path)` | No | `Hash` |
| `Ea::Qea.to_uml(database)` | Yes | `Lutaml::Uml::Document` |
| `Ea::Qea.parse(path)` | Yes | `Lutaml::Uml::Document` |

### 3. Bridge guard (`require_uml!`)
`to_uml` and `parse` call `require_uml!` which:
- Returns immediately if `Lutaml::Uml::Document` is already defined
- Tries `require "lutaml/uml"` if not
- Raises `Ea::Error` with a clear message if lutaml-uml is unavailable

### 4. Updated gemspec
- `lutaml-uml` listed with comment as optional (for UML bridge)
- Core deps clearly separated: `sqlite3`, `rubyzip`, `xmi`, `nokogiri`, `liquid`

### 5. Spec coverage
Added `spec/ea/qea/standalone_api_spec.rb` (7 examples) verifying:
- `load`, `load_database`, `to_uml` methods exist
- `load` works standalone with real fixture
- `to_uml` produces `Lutaml::Uml::Document`

## Verified dependency matrix

```
User wants...                      Needs lutaml-uml?
─────────────────────────────────────────────────────
Read EA database tables            No
Query EA objects by type           No
Get EA model statistics            No
Convert EA → UML Document          Yes
```
