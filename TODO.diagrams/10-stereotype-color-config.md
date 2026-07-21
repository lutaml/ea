# 10 - Stereotype Color Configuration (QEA fallback)

## Status: DONE (2026-07-21)

## Problem

When the source is QEA, the element's BCol is often the default
white. EA picks stereotype-based colors at render time when BCol
is not set. Our renderer currently hard-codes a stereotype →
color map, which is fragile.

## Approach

Externalize the stereotype → color map to a YAML configuration
file (`config/stereotype_colors.yml`). Users can override per
project.

The XMI source carries BCol directly from EA, so the config only
applies when BCol is missing (QEA sources without style data).

## Files

- `config/stereotype_colors.yml`
- `lib/ea/svg/stereotype_color_resolver.rb`
- `spec/ea/svg/stereotype_color_resolver_spec.rb`

## Verification

- Custom YAML overrides default map.
