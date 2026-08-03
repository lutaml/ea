# frozen_string_literal: true

module Ea
  module Svg
    # EaEmitter orchestrates SVG output that mirrors EA's layering
    # and naming conventions.
    #
    # Architecture:
    #
    #   Document (entry point)
    #     └─ LayerSequencer (frame?, theme via diagram.theme)
    #          ├─ Background
    #          ├─ DiagramFrame (opt-in)
    #          ├─ Elements → Element::* compartment renderers
    #          ├─ Connectors → Layer
    #          ├─ Markers → Marker::Registry (OCP) → Layer
    #          └─ Labels → TextRenderer
    #
    #   Cross-cutting:
    #     Canvas, BoundsCalculator, ColorResolver, FontResolver
    #     Ea::Theme::Definition / Registry / Loader (domain-level)
    #     TextRenderer, Style
    #
    # Theme is a top-level domain concept at Ea::Theme::*.
    # See lib/ea/theme.rb for the full API.
    #
    module EaEmitter
      autoload :Canvas, "ea/svg/ea_emitter/canvas"
      autoload :Background, "ea/svg/ea_emitter/background"
      autoload :BoundsCalculator, "ea/svg/ea_emitter/bounds_calculator"
      autoload :Style, "ea/svg/ea_emitter/style"
      autoload :Elements, "ea/svg/ea_emitter/elements"
      autoload :Connectors, "ea/svg/ea_emitter/connectors"
      autoload :Markers, "ea/svg/ea_emitter/markers"
      autoload :Labels, "ea/svg/ea_emitter/labels"
      autoload :GhostLabels, "ea/svg/ea_emitter/ghost_labels"
      autoload :Layer, "ea/svg/ea_emitter/layer"
      autoload :LayerSequencer, "ea/svg/ea_emitter/layer_sequencer"
      autoload :FontResolver, "ea/svg/ea_emitter/font_resolver"
      autoload :Marker, "ea/svg/ea_emitter/marker"
      autoload :Element, "ea/svg/ea_emitter/element"
      autoload :DiagramFrame, "ea/svg/ea_emitter/diagram_frame"
      autoload :TextRenderer, "ea/svg/ea_emitter/text_renderer"
      autoload :ColorResolver, "ea/svg/ea_emitter/color_resolver"
      autoload :Document, "ea/svg/ea_emitter/document"
      autoload :Label, "ea/svg/ea_emitter/label"
      autoload :Compartment, "ea/svg/ea_emitter/compartment"
      autoload :RenderContext, "ea/svg/ea_emitter/render_context"
    end
  end
end
