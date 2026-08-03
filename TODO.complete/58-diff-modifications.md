# TODO.complete/58: Diff comparator detects attribute modifications

## Status: open

Current `Ea::Diff::Comparator` only detects added / removed /
renamed entities. It misses modifications — e.g. an attribute's
type changed from "String" to "Integer", or a class's stereotype
changed.

## Plan

1. After identity matching, compare each record's `to_hash` between
   old and new.
2. If the hash differs (beyond name), emit a `:modified` change
   with a diff summary in `details`.
3. Add `Change#modified?` predicate (already exists in the struct).

## Acceptance

- Spec: changing an attribute type between old/new produces a
  :modified Change with the field name in details.
