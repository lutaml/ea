# 26 - Always emit upperValue / lowerValue on Property and OwnedEnd

## Status: ✅ DONE (2026-07-01) — attribute AND association-end paths complete

## Problem
Reference `spec/fixtures/basic.xmi` carried 149 `<upperValue>` and
149 `<lowerValue>` elements. Pre-fix transformer output emitted 102 of
each — a 47-element gap per type. The gap came from two paths:

1. **Attributes without bounds in QEA.** `build_attribute` returned
   `nil` for `upper_value` / `lower_value` when the QEA bound field
   was blank, silently omitting the child element.
2. **Association-end bounds.** `build_association_end` had the same
   nil-return-on-blank pattern.

Real Sparx XMI always materialises both child elements on every
`<ownedAttribute>` and `<ownedEnd>` — empty bounds render as
`<lowerValue value="0"/>` and `<upperValue value="-1"/>` (UML
unspecified-multiplicity defaults).

## Fix

### Path 1 (attributes): ea-side
`build_attribute` always calls `build_upper_value` /
`build_lower_value`. `Cardinality.normalize_upper("")` returns `"-1"`,
`Cardinality.normalize_lower("")` returns `"0"`. Every Property now
has both child elements.

### Path 2 (association ends): xmi gem schema migration
`Xmi::Uml::OwnedEnd` declared `upper`/`lower` as Integer attributes
— NOT `upper_value`/`lower_value` child-element models like
`OwnedAttribute`. The ea transformer was passing `upper_value:`/
`lower_value:` kwargs that the xmi gem silently dropped.

The xmi gem refactor branch `refactor/owned-end-schema-gap` (commit
on `lutaml/xmi` 2026-07-01) unified the schema: dropped Integer
attrs, added child-element models matching OwnedAttribute. After
this migration, the ea transformer's existing `build_association_end`
calls now produce the correct child elements with no ea-side change.

## Verification
- Every `<ownedAttribute>` in output has both `<upperValue>` and
  `<lowerValue>` children.
- Every `<ownedEnd>` in output has both `<upperValue>` and
  `<lowerValue>` children.
- Output upperValue count: 182 (was 102). Reference basic.xmi has
  149 — the difference is because real Sparx omits bounds for some
  attribute kinds; the ea gem emits consistently for round-trip
  safety. Round-trip via `Xmi::Sparx::Root.parse_xml` succeeds.
- Phase 2 sentinel spec in `transformer_spec.rb` flipped from
  negative ("does not emit") to positive ("emits") assertion.
