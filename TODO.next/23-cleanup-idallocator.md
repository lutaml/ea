# 23 - Clean up IdAllocator: dead constant, unused param, DRY

## Status: DONE (2026-07-01)

## Problem
`lib/ea/transformers/qea_to_xmi/id_allocator.rb` has three issues:

1. **Dead constant.** `LITERAL_UNLIMITED = "LI"` (line 16) is declared
   with a comment "Sparx reuses the LI prefix for both" but is never
   referenced anywhere in `lib/` or `spec/`. The comment explains
   intent that was never realised in code.

2. **Ignored parameter.** `for_multiplicity(value, seed:)` (line 31)
   takes a positional `value` arg (`:upper` or `:lower`) but never
   reads it. The method always uses `LITERAL_INTEGER`. Misleading API
   — callers believe the arg affects the output.

3. **DRY violation.** `allocate` and `for_multiplicity` have nearly
   identical bodies (counter increment, format with `LITERAL_INTEGER`,
   memoize by seed).

## Fix
- Drop `LITERAL_UNLIMITED`.
- Drop `for_multiplicity` entirely; have callers use `allocate` with
  the appropriate prefix constant.
- The transformer's two multiplicity callers
  (`build_upper_value`, `build_lower_value`) become:
  ```ruby
  id: @context.id_allocator.allocate(prefix: IdAllocator::LITERAL_INTEGER, seed: seed)
  ```

The xmi:type discriminator (`uml:LiteralUnlimitedNatural` vs
`uml:LiteralInteger`) is already set on the model constructor — it
does not belong in the ID allocator.

## Verification
- New `spec/ea/transformers/qea_to_xmi/id_allocator_spec.rb` covers
  `allocate` (counter, memoization, prefix).
- Full QeaToXmi specs unchanged at 39 examples.
- Grep confirms `LITERAL_UNLIMITED` and `for_multiplicity` no longer
  appear anywhere in `lib/` or `spec/`.
