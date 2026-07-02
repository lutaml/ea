# 37 - Visibility.boolean_from_flag returns real Ruby booleans

## Status: DONE (2026-07-02)

## Problem
`Ea::Transformers::QeaToXmi::Visibility.boolean_from_flag` returned
the strings `"true"` / `"false"` for EA's `"1"` / `"0"` flags. The
xmi gem's `is_*` attributes (`is_abstract`, `is_static`,
`is_ordered`, `is_derived`, `is_unique`, `is_id`, `is_read_only`,
`is_query`) were initially typed as `:string` so this worked — but
the xmi gem refactor migrated them to `:boolean` per UML 2.5 type
semantics.

After the migration, the ea-side `boolean_from_flag` returning
strings caused silent type coercion (Ruby `"true" == true` is
false; lutaml-model was lenient but the type contract was wrong).

## Fix
Return actual Ruby `true` / `false` (or `nil` when EA's field is
blank). Drop the ternary string coercion. Update the spec to assert
`be(true)` / `be(false)` instead of `eq("true")` / `eq("false")`.

```ruby
def boolean_from_flag(raw)
  return nil if raw.nil? || raw.to_s.strip.empty?

  raw.to_s == "1"
end
```

## Verification
- visibility_spec.rb: 6 examples pass with the new boolean contract.
- Output `isAbstract="false"` count for basic.qea: 80 (one per
  Class). All emit as lowercase XSD booleans per the xmi gem's
  lutaml-model :boolean type.
- Full qea_to_xmi suite passes (113 examples).
