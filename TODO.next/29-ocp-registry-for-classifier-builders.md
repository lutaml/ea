# 29 - OCP registry for QEA classifier builders

## Status: DONE (2026-07-01)

## Problem
`Transformer#build_classifier` (transformer.rb:179-187) dispatches on
`obj.transformer_type` via a `case/when` statement:

```ruby
case kind
when :class        then build_class(obj)
when :enumeration  then build_enumeration(obj)
when :data_type    then build_data_type(obj)
when :instance     then build_instance(obj)
end
```

CLAUDE.md explicitly says "Registry pattern for OCP — new types are
added by registration, not by modifying `case/when`". With 4
branches the cost is low, but the project rule is the project rule.

TODO 21 defended the case statement by saying "polymorphism lives in
the xmi gem's xmi:type discriminator on PackagedElement". That is
true for *XMI rendering shape* (the xmi gem picks the right element
name + child set based on `xmi:type`). It is **not** true for the
decision of *which EA row maps to which builder* — that decision is
made by `EaObject#transformer_type` and dispatched here. Adding a
new builder (e.g., `:signal`, `:interface`) still requires modifying
this method.

## Fix
Replace the case statement with a frozen hash of lambdas. Builders
are looked up by `transformer_type` symbol; unknown kinds return nil
(preserving current "skip" behaviour).

```ruby
CLASSIFIER_BUILDERS = {
  class:       ->(t, o) { t.build_class(o) },
  enumeration: ->(t, o) { t.build_enumeration(o) },
  data_type:   ->(t, o) { t.build_data_type(o) },
  instance:    ->(t, o) { t.build_instance(o) },
}.freeze

def build_classifier(obj)
  kind = obj.transformer_type || obj.object_type&.downcase&.to_sym
  CLASSIFIER_BUILDERS[kind]&.call(self, obj)
end
```

Adding a new kind now means adding one entry to the constant, no
method body change.

## Verification
- Behaviour unchanged: unknown kinds return nil (skipped downstream
  via `compact`).
- Spec for `build_classifier` covers all 4 known kinds and the
  unknown-kind fall-through.
- Project rule "Registry pattern for OCP" now satisfied.
