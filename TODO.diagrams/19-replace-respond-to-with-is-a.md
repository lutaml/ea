# TODO-D 19: Replace respond_to? with is_a? (encapsulation)

## Problem

`Ea::Svg::EaEmitter::Labels#connector_stereotype` uses
`respond_to?(:stereotype)`:

```ruby
def connector_stereotype(connector)
  rel = model_index ? model_index[connector.relationship_ref] : nil
  stereotype = rel&.respond_to?(:stereotype) ? rel.stereotype : nil
  return nil if stereotype.nil? || stereotype.to_s.empty?
  "«#{stereotype}»"
end
```

`respond_to?` is duck-typing that hides type errors until runtime.
Per the project rules: use `is_a?` for type checks, or design the
type hierarchy so the check isn't needed.

## Fix

`Ea::Model::Relationship` (base class) now declares `stereotype` as
an attribute. All concrete relationship subclasses inherit it. So
the check should be `rel.is_a?(Ea::Model::Relationship)`.

## Acceptance

- No `respond_to?` calls in `lib/`.
- Connector stereotype labels still render correctly.
- Specs pass.
