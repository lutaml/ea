# 52 - Theme::Definition with Integrated Fills

## Status: DONE (2026-07-26)

## Context

`ThemeColors` is a separate module mapping classifier types to
fill colors. This is a Theme concern — the colors ARE part of the
theme definition. Currently they're scattered across two modules.

## What needs to change

1. `Ea::Theme::Definition` gains a `fills` attribute (Hash:
   classifier class name → hex color)
2. `#fill_for(classifier)` method on Definition returns the
   per-type fill or nil
3. `#with(**overrides)` method returns a new Definition with the
   specified fields overridden (immutable editing pattern)
4. Built-in :default and :119 themes include their fills inline

## Acceptance

- Definition has `fills` Hash attribute
- Definition#fill_for(classifier) returns correct color per type
- Definition#with(**overrides) returns new Definition
- All existing specs pass
