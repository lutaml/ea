# 43 - Unify Color Computation (ColorResolver)

## Status: DONE (2026-07-26)

## Outcome

New `Ea::Svg::EaEmitter::ColorResolver` is single source of truth
for fill + stroke color decisions. Precedence chain:
1. element BCol (when present and not sentinel)
2. theme per-type pastel (when theme is themed)
3. stereotype color (via stereotype_resolver)
4. default fill

Same chain for stroke (LCol → theme.border → default).

Replaces 4 inline methods in Elements (resolve_fill, theme_fill_for,
fill_for_classifier, primary_stereotype).

## Files changed

- lib/ea/svg/ea_emitter/color_resolver.rb — NEW
- lib/ea/svg/ea_emitter.rb — autoload
- lib/ea/svg/ea_emitter/elements.rb — delegate to ColorResolver
- spec/ea/svg/ea_emitter/color_resolver_spec.rb — 10 specs
