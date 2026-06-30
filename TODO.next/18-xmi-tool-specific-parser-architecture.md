# 18 - XMI Tool-Specific Parser Architecture

## Status: DESIGN-CORRECT, CLOSED (2026-06-27)

## Decision
The architecture described in this document is correct as written and the
current `ea` codebase follows it:

- `Ea::Xmi::Parser` is hard-wired to Sparx via `::Xmi::Sparx::Root.parse_xml`
  — by design. `Ea::Xmi` means Sparx EA XMI, not generic XMI.
- `ea` does not claim to be the generic `.xmi` handler. `.xmi` registration
  uses content detection (see TODO.next/04) so non-Sparx XMI files fall
  through to other parsers.
- Future MagicDraw/Papyrus parsers will be **separate gems** with their own
  namespaces (`MagicDraw::Xmi`, `Papyrus::Xmi`), built on the `xmi` gem's
  `Xmi::Uml::*` shared base. OCP: adding a tool = adding a gem, not
  modifying this one.

## No further action needed in `ea`
This document is design rationale, not a backlog item. Closing it.

## Context

XMI (XML Metadata Interchange) is an OMG standard for serializing UML models.
**All major UML tools export XMI, but each adds tool-specific idiosyncrasies.**

| Tool | XMI flavor | Unique extension | Key differences from standard |
|---|---|---|---|
| Sparx EA | Sparx XMI | `.qea` (native DB) | EA stereotypes, EA tagged values, `{GUID}` format, `xmlns:ea=`, EA diagram objects |
| MagicDraw / Cameo | MagicDraw XMI | `.mdxml` | `com.nomagic` namespaces, MagicDraw-specific profiles, different diagram serialization |
| Eclipse Papyrus | Papyrus XMI | `.uml` | Eclipse namespaces, closer to UML 2.5 reference, OCL constraints |
| Standard OMG | XMI 2.x | `.xmi` (shared) | No tool extensions — pure UML 2.x |

## The `xmi` gem is already layered

The `xmi` gem (v0.5.10) provides:

```
Xmi::Uml::*          — generic UML/XMI elements (PackagedElement, etc.)
Xmi::Root            — base root parser
Xmi::Sparx::Root     — Sparx EA-specific schema
Xmi::EaRoot          — another EA root variant
Xmi::v20110701       — XMI 2.4.1 schema
Xmi::v20131001       — XMI 2.4.2 schema
Xmi::v20161101       — XMI 2.5 schema
Xmi::CustomProfile::* — profile extensions
```

This is the correct layering: **generic XMI infrastructure + tool-specific schemas**.

## Current state in `ea`

`Ea::Xmi::Parser` is hard-wired to Sparx (line 30):

```ruby
def get_xmi_model(xml)
  ::Xmi::Sparx::Root.parse_xml(File.read(xml))
end
```

It uses `::Xmi::Sparx::Element::*` throughout (`NoteLink`, `Generalization`,
`Aggregation`, `Association`). **It cannot parse MagicDraw or Papyrus XMI.**
This is correct — `Ea::Xmi` means Sparx EA XMI, not generic XMI.

## Architecture: each tool gets its own parser gem

### Naming convention

| Parser gem | Namespace | Parses | Uses |
|---|---|---|---|
| `ea` | `Ea::Xmi` | Sparx EA XMI | `Xmi::Sparx::Root` |
| `magicdraw` (future) | `MagicDraw::Xmi` | MagicDraw XMI | `Xmi::MagicDraw::Root` (to be added) |
| `papyrus` (future) | `Papyrus::Xmi` | Eclipse Papyrus XMI | `Xmi::Papyrus::Root` (to be added) |
| `xmi-standard` (future?) | `XmiStandard` | Pure OMG XMI 2.x | `Xmi::Root` |

### Dependency structure

```
xmi gem (generic XMI infrastructure + tool-specific schemas)
├── Xmi::Uml::*           (shared base — all tools use this)
├── Xmi::Sparx::*         (EA-specific extensions)
├── Xmi::MagicDraw::*     (future — MagicDraw extensions)
└── Xmi::Papyrus::*       (future — Papyrus extensions)

Each tool parser gem builds on xmi:
ea          →  uses Xmi::Sparx::*  +  Xmi::Uml::*
magicdraw   →  uses Xmi::MagicDraw::*  +  Xmi::Uml::*
papyrus     →  uses Xmi::Papyrus::*  +  Xmi::Uml::*
```

### Why separate gems, not one "universal XMI" parser

1. **Different idiosyncrasies.** Each tool has its own extensions, stereotypes,
   tagged value formats, and diagram serializations. A "universal" parser would
   be a pile of `if sparx? / if magicdraw? / if papyrus?` branches — worse than
   separate parsers.

2. **Different dependencies.** Sparx needs `sqlite3` (for QEA). MagicDraw needs
   its own profile libraries. Bundling them forces users to install deps they
   don't need.

3. **Independent release cycles.** Tools change their export formats. Each
   parser should be versioned independently.

4. **OCP.** Adding a new tool = adding a new gem, not modifying an existing one.

### What `ea` must NOT do

- `ea` must NOT register itself as the generic `.xmi` handler (see TODO.next/04)
- `ea` must NOT attempt to parse MagicDraw or Papyrus XMI files
- `ea`'s `.xmi` registration must use content detection to match ONLY Sparx EA
  XMI files (by checking for `"Enterprise Architect"` exporter, `xmlns:ea=`,
  etc.)

### Content detection signatures

Each tool's XMI has identifiable signatures in the file header:

```ruby
# Sparx EA
content.include?("Enterprise Architect") ||
  content.match?(/xmlns:ea=/) ||
  content.include?("<EA:")

# MagicDraw / Cameo
content.include?("MagicDraw") ||
  content.include?("com.nomagic") ||
  content.include?("nomagic")

# Eclipse Papyrus
content.include?("Papyrus") ||
  content.match?(/eclipse\.org/) ||
  content.match?(/xmlns:.*papyrus/)

# Standard OMG XMI (fallback — no tool signatures)
true
```

## Action items

### For `ea` (this gem)
1. Keep `Ea::Xmi::Parser` Sparx-specific — no changes to the parser itself
2. Register `.xmi` with content detection (not as the sole `.xmi` handler)
   — see TODO.next/04
3. Document in `Ea::Xmi::Parser` that it is Sparx-specific and will fail on
   non-Sparx XMI files

### For the `xmi` gem (separate repo)
1. Add `Xmi::MagicDraw::*` schema (when MagicDraw support is needed)
2. Add `Xmi::Papyrus::*` schema (when Papyrus support is needed)
3. These are extensions to the existing `xmi` gem, following the pattern set by
   `Xmi::Sparx::*`

### For future tool-specific parser gems
1. Follow the `ea` pattern: standalone gem, own namespace, optional `lutaml-uml`
   dependency
2. Register with `UmlRepository` via `register_extension` (unique extensions)
   or `register_format` (shared `.xmi` with content detection)
3. Build on the `xmi` gem's infrastructure, not on `ea`

## Why this matters

If `ea` claimed generic `.xmi`, a user with a MagicDraw file and both `ea` and
`lutaml-uml` loaded would get `Ea::Xmi::Parser.parse` — which calls
`::Xmi::Sparx::Root.parse_xml`. This would either:
- **Crash** — the Sparx schema doesn't understand MagicDraw extensions
- **Silently misparse** — applying EA assumptions to non-EA data, losing
  MagicDraw-specific information
- **Produce wrong results** — correct-looking but semantically incorrect UML

Content detection prevents this: the MagicDraw file has no EA signatures, so
`ea`'s loader is never selected for it.
