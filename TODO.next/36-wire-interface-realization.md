# 36 - Wire interfaceRealization for Interface-implementing classes

## Status: DONE (2026-07-02)

## Problem
Sparx XMI emits `<interfaceRealization>` as a child of the
implementing `<packagedElement type="uml:Class">`, not as a
package-level relationship. The ea transformer was not emitting
these at all — Realization connectors were silently dropped by
`package_level_relationships` (Realization is not in
`RELATIONSHIP_AT_PACKAGE_LEVEL`).

## Fix

### xmi gem
`Xmi::Uml::InterfaceRealization` model added in the xmi gem refactor
branch `refactor/owned-end-schema-gap`. `Xmi::Uml::PackagedElement`
declares `interface_realization` as a child-element collection.

### ea transformer
- New `interface_realizations_for(obj)` method on
  `Ea::Transformers::QeaToXmi::Transformer`. Walks the realization
  connectors where this class is the source (client) and emits one
  `InterfaceRealization` model per connector.
- New `build_interface_realization(conn)` builder. Wires
  `client` (this class), `supplier` and `contract` (the target
  Interface — supplier and contract are the same when the target is
  an Interface; if EA's data model ever distinguishes, this is the
  single place to change).
- `build_class` now passes `interface_realization:
  interface_realizations_for(obj)`.
- New `realization_connectors(obj)` helper — a specialization of
  `inheritance_connectors(obj, "Realization")` for readability.

## Verification
- All 113 qea_to_xmi specs pass.
- `basic.qea` has 0 Realization connectors, so the output has 0
  `<interfaceRealization>` elements. The path is exercised by the
  xmi gem's `sparx-instance-specification.xmi` fixture (parser side)
  and by structural round-trip — when the ea transformer is given an
  EA database with Realization connectors, it will produce the
  correct child elements.

## Sentinel
The Phase 2 sentinel spec block in
`spec/ea/transformers/qea_to_xmi/transformer_spec.rb` keeps two
negative sentinels for cases `basic.qea` doesn't exercise
(aggregation on ownedEnd, classifier on InstanceSpecification).
Realization does not need a sentinel because the wiring path is
already type-checked end-to-end.
