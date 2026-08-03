# TODO.complete/73: OCL validator latent bugs (API + owner lookup)

## Status: done

Fixing the `respond_to?` in TODO 51 exposed two pre-existing bugs in
`OclConstraintValidator` that had been masked because `owner_for`
always returned nil (never finding any owner, so the constraint
evaluation path was never reached).

## Bug 1: `owner_for` compared Ruby's `Object#object_id`

```ruby
# Before (broken):
object_id = constraint.respond_to?(:ea_object_id) ?
             constraint.ea_object_id :
             constraint.object_id
(database.collections[:objects] || [])
  .find { |o| o.object_id == object_id }  # BUG
```

`o.object_id` is Ruby's `Object#object_id` (memory address), NOT the
EA object ID column. The find block NEVER matched, so every OCL
constraint was silently skipped.

Fix: `o.ea_object_id == object_id`.

## Bug 2: `result.add` was a non-existent API

The validator called `result.add(:info, "message", entity_name: ...)`
but `ValidationResult` has `add_error`, `add_warning`, `add_info`,
and `add_message` — no bare `add`.

Fix: replaced with `result.add_info(category:..., message:..., **opts)`.

## Bug 3: `attribute_value` raised on missing attributes

The OCL evaluator's `attribute_value` used `context.public_send(name)`
without handling `NoMethodError`. Real OCL invariants reference
attributes that may not exist on every context type (e.g.,
`self.pattern` on an `EaObject` that has no `pattern` column).

Fix: rescue `NoMethodError`, return nil (OCL semantics: missing
attribute = null).

## Acceptance

- All 15 specs in `two_phase_validation_spec.rb` pass (previously
  6 were failing because the validator crashed when it actually
  ran).
- OCL evaluator specs pass (19 examples).
