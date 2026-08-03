# 34 - Per-Type Fill via Theme (Wire Up ThemeColors)

## Status: DONE (2026-07-25)

## Outcome

`Elements#resolve_fill` consults the active theme first:
1. Element BCol if present (highest precedence)
2. Theme's per-type fill (when theme is themed)
3. Stereotype color resolver (default theme)
4. DEFAULT_FILL (#FFFFFF)

Theme stroke color and width also override defaults.

## Files changed

- `lib/ea/svg/ea_emitter/elements.rb` — resolve_fill / resolve_stroke
  / resolve_stroke_width methods, theme lookup
