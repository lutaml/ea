# 31 - Specs for IdAllocator

## Status: DONE (2026-07-01)

## Problem
`Ea::Transformers::QeaToXmi::IdAllocator` is a public class with two
public methods (`allocate`, `for_multiplicity` at the time of the
audit; after TODO 23 it has just `allocate`). It has counter state,
seed-based memoisation, and prefix-based formatting. None of this
behaviour is directly tested — it is only exercised transitively via
the Transformer specs.

## Fix
New `spec/ea/transformers/qea_to_xmi/id_allocator_spec.rb`:

- `allocate` returns prefixed, zero-padded, monotonic IDs.
- Same seed → same ID (memoisation).
- Different seeds → different IDs.
- `nil` seed → still allocates (no memoisation).
- After TODO 25: parent GUID incorporation — `parent_guid` arg
  produces the Sparx `EAID_LI000001_<guid_tail>` format.
- Multiple parents with the same counter values produce distinct
  full IDs (GUID suffix disambiguates).

## Verification
File exists, runs cleanly with `bundle exec rspec`, and covers the
public `allocate` API exhaustively.
