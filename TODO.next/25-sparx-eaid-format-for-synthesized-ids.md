# 25 - Sparx-conformant EAID format for synthesized IDs

## Status: DONE (2026-07-01)

## Problem
Real Sparx XMI emits `<upperValue>` / `<lowerValue>` identifiers in
the form:

```
EAID_LI000001__EEB1_4de7_98F5_670D6EE4A52B
```

The `LI` prefix identifies a LiteralInteger; the suffix is the parent
element's GUID tail, making each synthesized ID globally unique and
traceable back to its owner.

The current IdAllocator emits bare counter IDs:

```
LI000009
```

No `EAID_` prefix, no GUID suffix. Two consequences:

1. **Not round-trip-safe.** Sparx importer may treat the IDs as
   foreign and synthesise new ones, breaking ID stability across
   import/export cycles.
2. **Not traceable.** A bare `LI000009` in serialized output gives
   no hint which element owns it; debugging serialized XMI is harder.

The spec parity tests did not catch this because they count
`<upperValue>` elements but never assert the ID shape.

## Fix
Two changes:

1. **IdAllocator gains a `parent_guid` parameter** on `allocate`.
   When provided, the allocated ID incorporates the parent GUID tail
   so it is traceable and Sparx-conformant.
2. **Transformer passes the parent object's GUID** at every
   allocation site.

New ID format: `EAID_<PREFIX><NN>_<GUID_TAIL>`

- `EAID_` prefix matches other element IDs (packages, classes).
- `<PREFIX>` is the well-known Sparx prefix (LI, SL, OE, RT, ...).
- `<NN>` is a zero-padded 6-digit counter scoped to the parent
  (so multiple LiteralIntegers on the same parent get distinct IDs).
- `<GUID_TAIL>` is the parent EA GUID with braces/dashes normalised
  to underscores (reusing `GuidFormat.ea_guid_to_xmi_id`'s normalisation).

For the legacy/no-parent case (synthesizing an ID without an owner
GUID), `allocate` still produces `EAID_<PREFIX><NN>` — better than
the bare `LI000009`, still uniquely identifiable.

## Verification
- New `id_allocator_spec.rb` asserts the Sparx format for both
  parented and parentless allocations.
- Transformer output now emits IDs like
  `EAID_LI000001_EEB1_4de7_98F5_670D6EE4A52B` matching the reference
  fixture's shape (verified against `spec/fixtures/basic.xmi`).
- Round-trip via `Xmi::Sparx::Root.parse_xml` still succeeds.
