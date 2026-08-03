# TODO.complete/59: Delete toy Export::Xmi::Generator

## Status: open

`Ea::Export::Xmi::Generator` is a minimal hand-rolled writer that
duplicates `Ea::Transformers::QeaToXmi`. The latter is the proper
serializer (used by `ea convert`). The export variant only emits
classes + attributes, missing relationships, packages, stereotypes.

Two options:
A) Delete Export::Xmi::Generator; route `ea export xmi` to
   Transformers::QeaToXmi.
B) Complete Export::Xmi::Generator to match Transformers.

Option A is correct — DRY. Eliminates ~100 lines of duplicate
logic that would otherwise drift.

## Plan

1. Change `lib/ea/cli/command/export.rb` xmi lambda to call
   `Ea::Transformers.qea_to_xmi(model)`.
2. Delete `lib/ea/export/xmi.rb`, `lib/ea/export/xmi/generator.rb`.
3. Remove `autoload :Xmi` from `lib/ea/export.rb`.
4. Update round_trip_spec to use the transformer.

## Acceptance

- `ea export xmi examples/qea/basic.qea` produces full Sparx XMI
  (not just classes).
- No `Ea::Export::Xmi` namespace remains.
