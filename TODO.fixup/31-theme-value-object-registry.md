# 31 - Theme Value Object + ThemeRegistry (OCP)

## Status: DONE (2026-07-25)

## Outcome

- Ea::Svg::EaEmitter::Theme — immutable value object
- Ea::Svg::EaEmitter::ThemeRegistry — registers and looks up themes
  by ID. Default + :119 themes built-in. register() for OCP
  extension.

## Files changed

- lib/ea/svg/ea_emitter/theme.rb — value object
- lib/ea/svg/ea_emitter/theme_registry.rb — registry with 2 themes
- lib/ea/svg/ea_emitter.rb — autoload
- spec/ea/svg/ea_emitter/theme_registry_spec.rb — 7 specs incl OCP
