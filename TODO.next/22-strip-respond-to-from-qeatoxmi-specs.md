# 22 - Strip `respond_to?` from QeaToXmi specs

## Status: DONE (2026-07-01)

## Problem
`spec/ea/transformers/qea_to_xmi/transformer_spec.rb:174` uses
`model.respond_to?(:packaged_element)` for duck-typing during the
recursive count walk. The project rule (CLAUDE.md) explicitly forbids
`respond_to?` for type dispatch — it hides type errors until runtime
and bypasses the type hierarchy.

## Fix
Replace with an explicit type check against the two xmi gem classes
that own `packaged_element`:

```ruby
def count_xmi_type_recursive(model, type)
  count = model.is_a?(::Xmi::Uml::PackagedElement) && model.type == type ? 1 : 0
  children = model.is_a?(::Xmi::Uml::PackagedElement) || model.is_a?(::Xmi::Uml::UmlModel) \
    ? model.packaged_element : []
  count + children.sum { |child| count_xmi_type_recursive(child, type) }
end
```

Both classes (`PackagedElement`, `UmlModel`) are the only xmi gem
types that own packaged children; the explicit `is_a?` check makes
that contract visible in the spec.

## Verification
`bundle exec rspec spec/ea/transformers/qea_to_xmi/` still passes
39 examples, 0 failures. Grep confirms no `respond_to?` remains in
`spec/ea/transformers/qea_to_xmi/`.
