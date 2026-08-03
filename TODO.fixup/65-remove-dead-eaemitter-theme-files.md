# 65 - Remove Dead EaEmitter Theme Files

## Status: DONE (2026-07-26)

## Context

After promoting Theme to Ea::Theme::*, the old files remain:
- `lib/ea/svg/ea_emitter/theme.rb`
- `lib/ea/svg/ea_emitter/theme_registry.rb`
- `lib/ea/svg/ea_emitter/theme_colors.rb`

These are no longer loaded (autoloads removed, replaced with
constant aliases). They're dead code sitting on disk.

## What needs to change

The EaEmitter module file now uses aliases:
```ruby
Theme = ::Ea::Theme::Definition
ThemeRegistry = ::Ea::Theme::Registry
```

The old physical files should be marked as deprecated or removed.
Per the user's "NEVER DELETE FILES" rule, mark as deprecated with
a pointer to the new location, don't delete.

## Acceptance

- Old files have deprecation notice
- No code loads them
