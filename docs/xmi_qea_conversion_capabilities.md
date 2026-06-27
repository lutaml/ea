# Format Conversion Capabilities: QEA, XMI, and UML

## Short answer

**No.** The `ea` gem cannot convert XMI→QEA or QEA→XMI. Neither direction
exists. Both formats are parsed *into* a common `Lutaml::Uml::Document`
(hub-and-spoke), but there is no write-back path to either native format.

## Current capability matrix

| From              | To                   | Status       | API                           |
|-------------------|----------------------|--------------|-------------------------------|
| `.qea` (SQLite)   | `Ea::Qea::Database`  | ✅ Full      | `Ea::Qea.load(path)`          |
| `.qea`            | `Lutaml::Uml::Document` | ✅ Full   | `Ea::Qea.parse(path)` / `to_uml(db)` |
| Sparx `.xmi`      | `::Xmi::Sparx::Root` model | ✅ Full | `Ea::Xmi::Parser.parse(path)` |
| Sparx `.xmi`      | Liquid drops (display) | ✅ Full    | `Parser.serialize_to_liquid`  |
| Sparx `.xmi`      | `Lutaml::Uml::Document` | ❌ None   | —                             |
| `Lutaml::Uml::Document` | Sparx `.xmi`    | ❌ None      | —                             |
| `Lutaml::Uml::Document` | `.qea` (SQLite) | ❌ None      | —                             |

## Why neither direction exists

### QEA is read-only

`Ea::Qea::Infrastructure::DatabaseConnection` opens SQLite with
`readonly: true`. There is no `INSERT`/`UPDATE` path, no writer class, no
`to_qea`. Building one requires reverse-mapping a UML Document into EA's
~30 interrelated tables (`t_object`, `t_package`, `t_connector`, `t_attribute`,
`t_diagram`, `t_objectproperties`, `t_xref`, `t_taggedvalue`, …), generating
valid EA GUIDs and object_ids, and populating tool-specific columns
(style strings, diagram geometry, visibility flags) that have no UML source.

### XMI is parse-only

`Ea::Xmi::Parser` consumes Sparx XMI via `::Xmi::Sparx::Root.parse_xml` and
exposes the result through Liquid drops for *display* rendering (HTML/JSON
templates). The drops wrap XMI-derived data — they do not serialize a
`Lutaml::Uml::Document` back to XMI. There is no `UmlDocument → XMI`
serializer.

### The drops are display, not generation

`Ea::Xmi::LiquidDrops::*` are Liquid `Drop` wrappers around the parsed XMI
model. They exist to render XMI content in templates (for browsing,
documentation, HTML export). A Liquid drop reads from a model; it does not
write one. To generate XMI, you'd need XMI-schema-aware serialization
(`xmi:Documentation`, `xmi:Extension`, `EAStub`, profile application, etc.),
which is a separate, substantial piece of work.

## What "conversion" would actually require

### QEA → XMI (export)

1. Build a `Lutaml::Uml::Document → Sparx XMI` serializer.
2. Lossy: the UML Document does not carry EA-specific data (diagram layout,
   style strings, tagged value geometry, t_xref cross-references). The
   exported XMI would be semantically faithful but visually bare.
3. The Sparx XMI schema is documented but large; `::Xmi::Sparx::Root`
   parses it but cannot (currently) serialize it.

### XMI → QEA (import)

1. Build `XMI → Lutaml::Uml::Document` (does not exist — `Ea::Xmi::Parser`
   produces display drops, not a UML Document).
2. Build `Lutaml::Uml::Document → QEA SQLite` writer (does not exist —
   see "QEA is read-only" above).
3. Highly lossy: EA's QEA schema has ~30 tables with tool-specific columns.
   Sparx's own XMI import into QEA is lossy; reimplementing it faithfully
   is a major project with marginal value (you'd produce a QEA that opens
   in EA but has no diagrams, no layout, no EA-specific metadata).

## Recommendation

Do **not** position the gem as offering XMI↔QEA conversion. Instead:

- **Read both formats into UML** — this is the gem's core value.
- **Query and analyze** the resulting UML Document (directly or via
  `Lutaml::UmlRepository::Repository.from_document`).
- **Export to neutral formats** — JSON, CSV, HTML (via Liquid drops),
  `.lur` package (via Repository). These are one-way, lossy, and honest
  about what they are.

If true XMI↔QEA round-trip is needed, the pragmatic path is to use Sparx EA
itself (which does both natively) and treat this gem as the
extract/query/analyze layer that sits alongside EA, not as a replacement
for its file-format converters.

## If we ever build write paths

The clean order would be:

1. **`Lutaml::Uml::Document → Sparx XMI`** — most useful, least schema
   complexity. Reuses `::Xmi::Sparx::Root`'s type system if serialization
   support is added upstream.
2. **`Lutaml::Uml::Document → .lur`** — already exists via
   `Repository.export_to_package`. Neutral, lossless for the UML subset.
3. **`Lutaml::Uml::Document → .qea`** — last resort. Only if EA-native
   interchange is a hard requirement and `.lur` + XMI export are
   insufficient.
