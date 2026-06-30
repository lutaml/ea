# 24 - Tighten QeaToXmi parity specs (exact counts, not ranges)

## Status: DONE (2026-07-01)

## Problem
The round-trip class count spec at
`spec/ea/transformers/qea_to_xmi/transformer_spec.rb:178-185` accepts
*any* count between 1 and the database class count:

```ruby
expect(actual).to be > 0
expect(actual).to be <= expected
```

That range-based parity hides regressions silently — if the
transformer started dropping half the classes, the spec would still
pass. The comment "the count is approximate" makes the looseness
explicit but doesn't justify it: every filter the transformer applies
(`transformer_type` returning nil for Note / Text / ProxyConnector)
is deterministic and countable.

## Fix
- Compute the expected count by applying the same filter
  `EaObject#transformer_type` applies, then assert equality.
- Document in the spec which object_types are intentionally dropped
  (Note, Text, ProxyConnector — see `ea_object.rb:177-208`).

```ruby
it "preserves class count from the database (filtering dropped types)" do
  # The transformer drops Note / Text / ProxyConnector rows because
  # they have no UML model equivalent (see EaObject#transformer_type).
  expected = database.objects.count { |o| o.transformer_type == :class }
  actual   = count_xmi_type_recursive(reparsed.model, "uml:Class")
  expect(actual).to eq(expected)
end
```

## Verification
- Round-trip class count spec now asserts equality.
- New spec covers enumeration and data_type round-trip counts with
  the same pattern.
- Full QeaToXmi specs pass.
