# 11 - Layer Sequencer Extraction

## Status: DONE (2026-07-24)

## Outcome

`Ea::Svg::EaEmitter::LayerSequencer` takes ownership of layer
ordering. Document shrinks to SVG envelope construction (~15 lines).

LayerSequencer exposes `layers` returning Array<String>; internally
composes Elements + Connectors + Markers + Labels, and merges
same-style Layer structs.

## Files changed

- `lib/ea/svg/ea_emitter/layer_sequencer.rb` — NEW sequencer
- `lib/ea/svg/ea_emitter.rb` — autoload registration
- `lib/ea/svg/ea_emitter/document.rb` — delegates to LayerSequencer
