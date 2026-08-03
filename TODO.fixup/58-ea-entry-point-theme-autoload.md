# 58 - EA::Ea.rb Entry Point Autoload for Theme

## Status: DONE (2026-07-26)

## Context

`Ea::Theme` is a new top-level namespace. It needs proper autoload
registration in `lib/ea.rb` (the gem entry point).

## What needs to change

1. `lib/ea/theme.rb` — module entry file with autoloads
2. `lib/ea.rb` adds `autoload :Theme, "ea/theme"`
3. All Theme sub-files follow autoload pattern

## Acceptance

- `require "ea"` makes `Ea::Theme::*` available
- No require_relative in any Theme file
- All autoloads defined in `lib/ea/theme.rb`
