# TODO.complete/51: Remove `respond_to?` from lib code

## Status: done

The user's rule: "never use respond_to (poor typing)". All 6 call
sites in lib/ have been replaced with `is_a?` type checks or direct
method calls (typed dispatch).

## Sites fixed

1. `lib/ea/qea/validation/database/ocl_constraint_validator.rb:54` —
   `constraint.respond_to?(:ea_object_id)` → direct call (constraint
   is always `EaObjectConstraint`, which has `ea_object_id`). Also
   fixed latent bug: `o.object_id` (Ruby's `Object#object_id`) →
   `o.ea_object_id`; the old code never matched any owner, silently
   skipping all OCL validation.

2. `lib/ea/export/json/generator.rb:64` —
   `record.class.respond_to?(:primary_key_column)` →
   `record.is_a?(Ea::Qea::Models::BaseModel)` (BaseModel defines
   `primary_key_column` as a class method).

3. `lib/ea/export/json/generator.rb:72` —
   `record.respond_to?(:name)` → `record.to_hash["name"]` (safe hash
   access, returns nil when absent).

4. `lib/ea/ocl/evaluator.rb:66` —
   `collection.respond_to?(:size)` → `collection.is_a?(Array)`.

5. `lib/ea/ocl/evaluator.rb:73` —
   `collection.respond_to?(:empty?)` → `collection.is_a?(Array)`.

6. `lib/ea/export/plantuml/generator.rb:130` —
   `l.respond_to?(:ea_object_id)` →
   `l.is_a?(Ea::Qea::Models::EaAttribute)`.

## Follow-on fixes

Fixing site #1 exposed two latent bugs in the OCL constraint
validator that had been masked by the `owner_for` always returning nil:

- `result.add(:info, ...)` was calling a non-existent API — replaced
  with `result.add_info(category:..., message:..., **opts)`.
- The OCL evaluator's `attribute_value` raised `NoMethodError` on
  unknown attributes — now rescues and returns nil (OCL semantics:
  missing attribute = null).

## Acceptance

- `grep -rn "respond_to?" lib/` returns zero results.
- All validation + OCL specs pass (including the previously-skipped
  OCL validation specs that now run to completion).
