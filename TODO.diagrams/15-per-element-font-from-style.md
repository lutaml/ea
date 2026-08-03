# 15 - Per-Element Font from Style

## Status: DONE (2026-07-23)

## Outcome

Added `Ea::Svg::EaEmitter::FontResolver` that resolves font family +
size + weight + style per element, using EA's fallback chain:

1. Element-level `font_family` / `font_size` (set from EA's
   `font=NAME;fontsz=PCT` style fields via ExtensionStyleParser)
2. Diagram-level default (most common non-nil value across elements)
3. Module default (`Yu Gothic UI`, `13`)

`Elements` emitter delegates font resolution to FontResolver so the
fallback rule lives in one place (MECE).

## Files changed

- `lib/ea/svg/ea_emitter/font_resolver.rb` — new resolver
- `lib/ea/svg/ea_emitter.rb` — autoload registration
- `lib/ea/svg/ea_emitter/elements.rb` — uses FontResolver
- `spec/ea/svg/ea_emitter/font_resolver_spec.rb` — 9 specs covering
  explicit, fallback, and empty-diagram cases
