# 51 - Promote Theme to Ea::Theme Top-Level Namespace

## Status: DONE (2026-07-26)

## Context

Theme is currently `Ea::Svg::EaEmitter::Theme` — buried inside the
SVG emitter. But Theme is a DOMAIN concept (visual style), not
rendering-specific. Other consumers (HTML docs, image rendering,
documentation generation) will also need themes.

The current placement violates MECE: Theme logic is mixed with
SVG rendering concerns.

## What needs to change

1. New `Ea::Theme` module at top level (in `lib/ea/theme.rb`)
2. Move `Ea::Svg::EaEmitter::Theme` → `Ea::Theme::Definition`
3. Move `Ea::Svg::EaEmitter::ThemeRegistry` → `Ea::Theme::Registry`
4. Move `Ea::Svg::EaEmitter::ThemeColors` → merge into Definition
5. Backward-compat aliases in EaEmitter (temporary)

## Acceptance

- Ea::Theme module exists with autoloads for Definition, Registry
- Ea::Svg::EaEmitter::Theme aliases to Ea::Theme::Definition
- All existing specs pass
- New spec verifies the namespace move
