# 62 - Theme Builder DSL

## Status: DONE (2026-07-26)

## Context

Creating themes programmatically via `Definition.new(id:..., font_family:..., ...)`
is verbose. A builder DSL provides a more ergonomic, intention-revealing API.

## Proposed API

```ruby
Ea::Theme.build("my_theme", name: "My Theme") do |t|
  t.font family: "Arial", size: 12, unit: "px"
  t.text color: "#333333", weight_normal: 400
  t.border color: "#666666", stroke_width: 1
  t.fill "Ea::Model::Klass" => "#F0F0F0"
end
```

## What needs to change

1. `Ea::Theme.build(id, name: nil)` yields a builder
2. Builder methods set attributes
3. Returns a Definition registered in Registry

## Acceptance

- DSL creates valid Definition
- Definition is registered for lookup
- New spec covers DSL usage
