# 01 - Gem Identity: `ea` is standalone, not `lutaml-ea`

## Decision

The gem stays **`ea`** with namespace **`Ea::*`**. It is a standalone Enterprise
Architect parser, not a Lutaml ecosystem plugin.

## Rationale

### Two audiences

1. **EA parser users** — "I have a `.qea` file, I want to read its objects,
   connectors, packages, render diagrams." This user does not know or care about
   Lutaml. They should be able to `gem install ea` and start parsing.

2. **Lutaml ecosystem users** — "I want to parse QEA → UML Document → LML →
   publish." This user adds `ea` alongside `lutaml-uml` in their Gemfile.

Calling the gem `lutaml-ea` with namespace `Lutaml::Ea::*` serves only audience
2 and actively harms audience 1 — they'd be importing a namespace and
dependency chain they don't need.

### Why `ea`, not `lutaml-ea`

The `lutaml-` prefix is for gems that define the Lutaml core model:
- `lutaml-model` — the serialization framework
- `lutaml-uml` — the UML metamodel
- `lutaml-lml` — the LML DSL

`ea` is a **parser for an external tool**. It's an adapter, not core
infrastructure. Adapters should have their own identity:

| Pattern | Core gem | Adapter gem |
|---|---|---|
| ActiveRecord | `activerecord` | `pg`, `mysql2` (not `ar-pg`) |
| Nokogiri | `nokogiri` | (self-contained) |
| Lutaml | `lutaml-uml` | `ea` (not `lutaml-ea`) |

### What this eliminates

- **No namespace migration.** The current `Ea::*` namespace is correct. We skip
  the entire rename plan (all 130 source files, 130 spec files, gemspec, CLAUDE.md).
- **No `Lutaml::Ea` confusion.** The namespace is `Ea::Qea`, `Ea::Diagram`,
  etc. — clean, short, unambiguous.
- **The gemspec stays `ea.gemspec`.** No rename needed.

### Dependency graph

```
ea (standalone — depends on sqlite3, rubyzip, nokogiri, xmi, liquid)
  └── [optional] lutaml-uml (for Ea::Qea.to_uml bridge)

lutaml-uml (UML metamodel + UmlRepository + SPA)
  └── lutaml-lml
          └── lutaml (meta-bundle)
```

`lutaml-uml` has **zero** dependency on `ea`. `ea` optionally depends on
`lutaml-uml`. The `lutaml` meta-bundle does not need to add `ea` — it's
available for users who need it.

### What remains in `lutaml-uml` after slimming

- `Lutaml::Uml::*` (251 files) — generic UML metamodel
- `Lutaml::UmlRepository::*` (92 files) — querying, SPA, exporters
- `frontend/` — Vue 3 SPA (generic UML model browser)
- No EA, QEA, Sparx, SQLite references

### What gets deleted from `lutaml-uml`

- `Lutaml::Qea::*` (87 files) — moves to `Ea::Qea::*` (already done in this repo)
- `Lutaml::Ea::Diagram::*` (14 files) — moves to `Ea::Diagram::*` (already done)
- `Lutaml::Xmi::*` (22 files) — moves to `Ea::Xmi::*` (already done)
- `Lutaml::ModelTransformations::*` (6 files) — moves to `Ea::Transformations::*`
- `Lutaml::Cli::Uml::*` — deleted (EA-flavored CLI, no replacement)
- `config/qea_schema.yml`, `config/diagram_styles.yml` — already in `ea` repo
