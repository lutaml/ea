# TODO.complete/41: Round-trip stability spec

## Status: done

The contract `parse → serialize → parse` should produce identical
models. Currently there's no spec that verifies this end-to-end.

## Plan

1. Spec: load basic.qea, serialize to XMI via `ea export xmi`,
   re-parse the XMI, assert element counts match.
2. Spec: load test.qea, serialize to JSON, re-parse, assert counts.
3. Spec: parse → to_hash → from_hash for each model class.

## Acceptance

- Round-trip count delta ≤ 0 for every collection.
- New spec file `spec/ea/integration/round_trip_spec.rb`.
