# 30 - Replace ad-hoc Hash return with Struct in build_association_end

## Status: DONE (2026-07-01)

## Problem
`Transformer#build_association_end` (transformer.rb:326-344) returns
a two-key Hash:

```ruby
{ xmi_id: end_id, model: model }
```

The caller (`build_association`) destructures it as
`dest_end[:xmi_id]`, `dest_end[:model]`. Ad-hoc Hash returns are
fragile — typos in keys (`[:xmii_id]`) fail silently as nil, and
the contract is invisible at the method signature.

## Fix
Define a frozen Struct for the return type:

```ruby
AssociationEnd = Struct.new(:xmi_id, :model)
```

`build_association_end` returns `AssociationEnd.new(end_id, model)`.
Caller uses `dest_end.xmi_id`, `dest_end.model` — typos now raise
NoMethodError at the call site.

The Struct lives in the QeaToXmi namespace
(`Ea::Transformers::QeaToXmi::AssociationEnd`) so it can be referenced
in specs and reused by future wire-up code.

## Verification
- `build_association` reads `dest_end.xmi_id` / `dest_end.model`
  instead of hash keys.
- Spec covers `build_association_end` directly, asserting the Struct
  shape and the synthesised IDs.
