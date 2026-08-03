# 54 - Diagram#theme and #theme= API

## Status: DONE (2026-07-26)

## Context

Currently `Diagram` has `theme_id` (string from style_ex) but
no way to get or set the resolved Theme Definition object. Users
cannot:
- Get the active theme: `diagram.theme`
- Set a theme: `diagram.theme = :119`
- Override theme on a specific diagram: `diagram.theme = custom_def`

## What needs to change

1. `Diagram#theme` — returns resolved Definition:
   - theme_override if set
   - Registry.lookup(theme_id) otherwise
   - Registry::DEFAULT if neither
2. `Diagram#theme=(value)` — accepts:
   - `Ea::Theme::Definition` instance → sets theme_override
   - String ID (":119") → sets theme_id, clears override
   - Symbol ID (:119) → sets theme_id, clears override
3. `Diagram#theme_override` — stores explicit Definition
4. JSON mapping for theme_id and theme_override

## Usage

```ruby
# Read theme
diagram.theme  # → Ea::Theme::Definition

# Set by ID
diagram.theme = :119
diagram.theme = ":119"

# Set custom definition
diagram.theme = Ea::Theme::Definition.new(id: "custom", ...)

# Edit existing theme (immutable → new instance)
diagram.theme = diagram.theme.with(text_color: "#FF0000")
```

## Acceptance

- Diagram#theme returns Definition
- Diagram#theme= accepts Definition, String, Symbol
- Diagram#theme_override stores explicit Definition
- JSON round-trip preserves theme_id and theme_override
- New specs cover all access patterns
