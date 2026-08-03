# 73 - Delete dead Transformations subsystem

## Status: COMPLETE (2026-07-26)

Removed `lib/ea/transformations/parsers/` (BaseParser, QeaParser,
XmiParser), `format_registry.rb`, `transformation_engine.rb`,
`configuration.rb`, plus their specs.

Production entry points (`Ea::Transformations.parse` and `.to_uml`)
already bypassed these wrappers and called `Ea::Qea.load`,
`Ea::Xmi.load`, and `Ea::Bridge::*` directly. The "engine" layer was
dead weight that only specs referenced.

Slimmed `lib/ea/transformations.rb` from 130 lines to 47.
