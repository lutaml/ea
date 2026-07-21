# frozen_string_literal: true

module Ea
  module Svg
    # EaEmitter orchestrates SVG output that mirrors EA's layering
    # and naming conventions:
    #
    # 1. XML declaration + DOCTYPE (SVG 1.0)
    # 2. Root <svg> with cm dimensions + viewBox
    # 3. <title></title> + <desc>Created with Enterprise Architect..</desc>
    # 4. Background <g> with full-canvas white rect
    # 5. Per-element groups, layered: shape <g>, text <g>, divider
    #    <g>, attribute text <g>
    # 6. Per-connector groups: path <g> and polygon <g>
    # 7. Final labels <g> with all connector text
    #
    # Distinct from Ea::Svg::Renderer which produces a thinner
    # output for diagrams that don't carry full EA style data.
    module EaEmitter
      autoload :Canvas, "ea/svg/ea_emitter/canvas"
      autoload :Background, "ea/svg/ea_emitter/background"
      autoload :Elements, "ea/svg/ea_emitter/elements"
      autoload :Connectors, "ea/svg/ea_emitter/connectors"
      autoload :Markers, "ea/svg/ea_emitter/markers"
      autoload :Labels, "ea/svg/ea_emitter/labels"
      autoload :Document, "ea/svg/ea_emitter/document"
    end
  end
end
