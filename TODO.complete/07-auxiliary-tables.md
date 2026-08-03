# TODO.complete/07: Auxiliary QEA tables

## Status: done

EA has ~96 tables. We currently parse 24. Beyond the structural core
(objects, connectors, diagrams, packages, operations, attributes, xref),
several tables carry semantic value for the CLI replacement vision.

## Tables worth adding

| Table | Purpose | CLI value |
|---|---|---|
| t_glossary | Term definitions | Documentation |
| t_version | Version control history | Audit |
| t_phase | Project phases | PM integration |
| t_lists | Enumeration lists | Validation |
| t_secuser / t_secgroup | Permissions (locked QEA) | Access control |
| t_secrypt | Encryption metadata | Security analysis |
| t_authors | Authors | Audit |
| t_clients | Client definitions | CRM-lite |
| t_resources | Resource allocation | PM |
| t_tasks | Tasks | PM |
| t_issues | Issue tracking | Bug tracker |
| t_risks | Risk register | PM |

## Plan

Add these incrementally as demand appears. Each follows the same pattern:

1. Raw-row model in `lib/ea/qea/models/ea_{table}.rb` (autoload from `models.rb`).
2. Wire into `config/qea_schema.yml`.
3. Wire into `DatabaseLoader`.
4. Expose via `Database#collections[:{table}]`.
5. CLI exposes via `ea stats` and lookup methods.

## Priority order

1. **t_glossary** — simple key/value, useful for documentation.
2. **t_version** — version history, useful for audit.
3. **t_authors** — already partly referenced by other tables.

The rest (PM/CRM/security) are low priority unless a user requests them.

## Acceptance

- Spec: each table has a raw-row model with COLUMN_MAP.
- Spec: `ea stats FILE` includes the new table count.
