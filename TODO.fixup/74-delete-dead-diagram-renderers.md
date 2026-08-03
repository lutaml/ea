# 74 - Delete dead Diagram legacy renderers

## Status: COMPLETE (2026-07-26)

Removed `lib/ea/diagram/{svg_renderer, layout_engine, style_parser,
path_builder, style_resolver, configuration, util, element_renderers,
extractor}.rb` plus their specs. These served the legacy
lutaml-uml-backed rendering pipeline that was already replaced by
`Ea::Svg::EaEmitter`.

Kept:
- `lib/ea/diagram/display_config.rb` — used by `Ea::Model::Diagram`
- (extractor moved to modern pipeline; see below)

Rewrote `lib/ea/cli/command/diagrams.rb` `extract` action to use
`Ea::Sources::{Qea,Xmi}::Adapter` + `Ea::Svg::EaEmitter::Document`
directly, removing its dependency on lutaml-uml/Repository. The
`list` action now uses the same modern adapters.
