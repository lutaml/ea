# 45 - Theme-Aware FontResolver

## Status: DONE (2026-07-26)

## Outcome

FontResolver constructor accepts optional `theme:` param.
Precedence chain:
1. element.font_family (per-element override)
2. theme.font_family (when theme is themed)
3. diagram-default (most common element font)
4. locale fallback (Calibri 10)

Same for size. Added `size_unit_for` and theme-aware weight_for.

Elements passes theme via `FontResolver.new(diagram, theme: theme)`.

## Files changed

- lib/ea/svg/ea_emitter/font_resolver.rb — theme param + size_unit
- lib/ea/svg/ea_emitter/elements.rb — pass theme to FontResolver
- spec/ea/svg/ea_emitter/font_resolver_spec.rb — theme :119 specs
