# 30 - Theme System & Per-Type Fills (Stub)

## Status: PARTIAL (stubbed, needs full implementation)

## Implemented

- `Ea::Svg::EaEmitter::ThemeColors` module declares Theme :119's
  per-classifier-type fill colors:
  - Class → #FDFAF7
  - Interface → #F1ECFA
  - DataType → #FAF9E6
  - Enumeration → #E8FDE3
  - PrimitiveType → #FAF9E6
  - Plus border color #9A8484 and text color #595959

## Not yet implemented

1. **Theme detection**: read `t_diagram.StyleEx` `Theme=:NNN` flag
   via QEA parser. Requires plumbing StyleEx through to the SVG
   emitter via the Diagram model.
2. **Theme application**: when theme is :119, override:
   - Element fill → per-type pastel
   - Element border color → #9A8484
   - Text color → #595959
   - Stroke width → 1 (was 2)
   - Font family → Carlito
   - Font size → 7pt (not 13px)
3. **StyleEx flag honoring**: `SuppressFOC=1`, `AttPkg=1`,
   `ShowNotes=0`, `ShowBorder=1`, etc.
4. **DiagramObject coord normalization**: QEA stores rect with
   negative y values; need to normalize to canvas coords.

## How to wire up

The current XMI adapter doesn't capture StyleEx. The QEA adapter
would need to expose it. Then Document constructor accepts a
theme override or reads from the diagram model.

Quick path: add `style_ex` field to `Ea::Model::Diagram`, populate
from XMI/QEA, then `Document.new(diagram, model_index:, theme: :auto)`
extracts theme from style_ex.

## Files changed (stub only)

- `lib/ea/svg/ea_emitter/theme_colors.rb` — color constants
- `lib/ea/svg/ea_emitter.rb` — autoload
