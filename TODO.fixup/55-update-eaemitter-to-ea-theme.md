# 55 - Update EaEmitter to Use Ea::Theme Namespace

## Status: DONE (2026-07-26)

## Context

After promoting Theme to Ea::Theme (TODO 51), the EaEmitter must
reference the new paths. ColorResolver, FontResolver, Elements,
and LayerSequencer all reference `ThemeRegistry.lookup(diagram.theme_id)`.

## What needs to change

1. All `Ea::Svg::EaEmitter::ThemeRegistry` → `Ea::Theme::Registry`
2. All `Ea::Svg::EaEmitter::Theme` → `Ea::Theme::Definition`
3. `Diagram#theme` (from TODO 54) replaces `ThemeRegistry.lookup(diagram.theme_id)`
4. ColorResolver and FontResolver accept `Definition` directly
5. Keep backward-compat aliases in EaEmitter (deprecated)

## Acceptance

- EaEmitter references Ea::Theme::*
- diagram.theme used everywhere (replacing manual Registry lookup)
- All existing specs pass
