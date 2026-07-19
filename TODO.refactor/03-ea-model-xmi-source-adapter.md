# 03 - XMI Source Adapter

## Status: DONE (2026-07-19)

## Problem

Sparx-flavored XMI files (`.xmi`) parse into `Xmi::Sparx::Root`.
Same harmonization problem as QEA — different format, same model.

## Approach

`Ea::Sources::Xmi::Adapter` mirrors the QEA adapter's structure
(coordinator + per-element builders), but reads from the parsed
`Xmi::Sparx::Root` tree instead of SQLite tables. Builders
dispatch on `xmi:type` discriminator (`uml:Class`,
`uml:Association`, etc.).

Deferred until TODOs 01, 02, 06, 10 are green so the SPA pipeline
proves itself on QEA first (the perf pain point). XMI is already
served by the existing `lutaml-uml` pipeline; the EA-native QEA
pipeline is the gap.

## Files

- `lib/ea/sources/xmi.rb` + `lib/ea/sources/xmi/adapter.rb` +
  per-element builders
- `spec/ea/sources/xmi/*_spec.rb`

## Verification

- Round-trip on existing `spec/fixtures/*.xmi`
- Parity assertions vs the QEA adapter where the same model is
  available in both formats
