# 33 - Text Encoding: Decimal Coords + Rotation Transform

## Status: DONE (2026-07-25)

## Outcome

New `Ea::Svg::EaEmitter::TextRenderer` is the single source of
truth for `<text>` emission. Always emits:
- Decimal `x` and `y`: `x="11.00" y="19.00"`
- Always-present rotation transform: `transform="rotate(-0.00 X Y)"`
- Integer `textLength`
- Proper XML escaping

Refactored 6 sites to delegate:
- `Element::HeaderRenderer`
- `Element::AttributeRenderer`
- `Element::OperationRenderer`
- `Element::EnumerationLiteralRenderer`
- `Labels#text_at`
- `DiagramFrame#build_label_text`

Also closes TODO 42 (TextRenderer Centralization).

## Files changed

- `lib/ea/svg/ea_emitter/text_renderer.rb` — NEW
- `lib/ea/svg/ea_emitter.rb` — autoload
- 6 renderer files refactored to use TextRenderer
- `spec/ea/svg/ea_emitter/text_renderer_spec.rb` — 10 specs
