# TODO.complete/51: Remove `respond_to?` from lib code

## Status: open

The user's rule: "never use respond_to (poor typing)". Five call
sites violate it, all added in recent sessions:

- lib/ea/svg/ea_emitter/element/stereotype_icon_renderer.rb:61
- lib/ea/lint/rules/missing_stereotype.rb:29
- lib/ea/query/builder.rb:66
- lib/ea/ocl/evaluator.rb:41, 52

## Plan

Replace `respond_to?(:x)` with explicit type checks via `is_a?`:

- For `stereotype_refs` checks: `classifier.is_a?(Ea::Model::Classifier)`
  (Classifier is the only type that owns stereotype_refs).
- For `each` checks: `collection.is_a?(Array)` (collections are
  always Arrays in our model; nil-safe via early return).

## Acceptance

- `grep -rn "respond_to?" lib/ea/` returns 0 hits.
- Existing specs still pass.
