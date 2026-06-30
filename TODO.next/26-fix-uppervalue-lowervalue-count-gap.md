# 26 - Always emit upperValue / lowerValue on Property

## Status: PARTIALLY DONE (2026-07-01) — attribute path complete; association-end path blocked on xmi gem

## Problem
Reference `spec/fixtures/basic.xmi` carries 149 `<upperValue>` and
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

### Path 1 (attributes): DONE
`build_attribute` always calls `build_upper_value` /
`build_lower_value`. `Cardinality.normalize_upper("")` returns `"-1"`,
`Cardinality.normalize_lower("")` returns `"0"`. Every Property now
has both child elements.

### Path 2 (association ends): BLOCKED on xmi gem
`Xmi::Uml::OwnedEnd` declares `upper` and `lower` as Integer
attributes — NOT `upper_value` / `lower_value` child-element models
like `OwnedAttribute`. The xmi gem's schema for OwnedEnd is
inconsistent with OwnedAttribute:

```
OwnedAttribute.upper_value : Type = Xmi::Uml::UpperValue  (child element)
OwnedEnd.upper            : Type = :integer                (attribute)
```

Until the xmi gem unifies these (small focused PR to lutaml/xmi),
`build_association_end` cannot emit `<upperValue>` / `<lowerValue>`
child elements on `<ownedEnd>`. The 47-element gap (149 vs 102)
persists for this reason.

This is tracked as TODO.next/21 §2 ("xmi gem attribute gaps") — the
list there should add "OwnedEnd.upper_value / lower_value child
models matching OwnedAttribute".

## Verification
- Attributes path: every `<ownedAttribute>` in output now has both
  `<upperValue>` and `<lowerValue>` children (count = attribute count).
- Association-end path: still no child elements (blocked on xmi gem).
- Round-trip via `Xmi::Sparx::Root.parse_xml` still succeeds.
- Phase 2 sentinel spec (TODO 32) will flip from negative to positive
  assertion when the xmi gem adds the models.
