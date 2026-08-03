# 32 - StyleEx on Diagram Model

## Status: DONE (2026-07-25)

## Outcome

Added `style_ex` attribute to `Ea::Model::Diagram` with two
helper methods:
- `#style_ex_flags` — parses "Key=Value;Key=Value" into Hash
- `#theme_id` — extracts Theme=:NNN value

## Note: StyleEx not exposed via XMI

EA's XMI export does NOT include `t_diagram.StyleEx`. The QEA
loader (when wired into the SVG pipeline) will populate this
field directly. For XMI-loaded diagrams, style_ex stays nil and
the default theme is used.

## Files changed

- `lib/ea/model/diagram.rb` — added style_ex attribute + helpers
- `spec/ea/model/diagram_style_ex_spec.rb` — 7 specs
