# 11 - MECE: Consolidate Style Knowledge

## Status: DONE (2026-06-27)

## Applied
1. **Stripped dead StyleParser API.** `parse_element_style`,
   `parse_connector_style`, `get_base_element_style`,
   `element_specific_style`, `parse_ea_style_string`,
   `stereotype_style` were unused — callers went through
   `StyleResolver#resolve_element_style` /
   `StyleResolver#resolve_connector_style`. The duplicate API was removed
   to fix the MECE violation (two style pipelines for the same concern).
2. **Removed unused constants** `EA_COLORS`, `EA_TYPOGRAPHY`, `EA_STROKES`.
3. **What remains in StyleParser:** `color_from_ea_color` — the BGR-integer →
   hex converter that StyleResolver calls when parsing EA style strings.

## What was deliberately left alone
- `Configuration#style_for` — has direct spec coverage and serves a different
  concern (config-layer resolution with class/package/stereotype/defaults
  priority). StyleResolver handles **EA-data-driven** resolution; Configuration
  handles **YAML-driven** resolution. They are now MECE: EA-parsed overrides
  live only in StyleResolver, YAML defaults live only in Configuration.
- `StyleResolver#style_resolver.rb:245` regex on `connector.class.name` was
  audited — the file uses `is_a?` throughout; no regex type-check remains.

## Files
- `lib/ea/diagram/style_parser.rb` — stripped to single live method
- `lib/ea/diagram/style_resolver.rb` — unchanged (already correct)
- `lib/ea/diagram/configuration.rb` — unchanged (YAML layer only)

## Verification
- Full ea suite: 1953 examples, 0 failures, 37 pending

