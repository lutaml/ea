# frozen_string_literal: true

module Ea
  # Ea::Svg is a consumer adapter of Ea::Model::Diagram — it
  # projects the umldi (UML Diagram Interchange) content of a
  # diagram into standalone SVG. Coordinates are taken straight
  # from the source: EA's pixel space (rectleft, recttop,
  # rectright, rectbottom, t_diagramlinks.geometry) or XMI's
  # uml:Diagram owned_element bounds.
  #
  # Distinct from Ea::Diagram::SvgRenderer which operates on the
  # legacy Lutaml::Uml::Document pipeline. This module consumes
  # the canonical Ea::Model types only.
  module Svg
    autoload :BoundsCalculator, "ea/svg/bounds_calculator"
    autoload :StyleResolver, "ea/svg/style_resolver"
    autoload :StereotypeColorResolver, "ea/svg/stereotype_color_resolver"
    autoload :ElementBox, "ea/svg/element_box"
    autoload :ConnectorPath, "ea/svg/connector_path"
    autoload :Renderer, "ea/svg/renderer"
    autoload :EaEmitter, "ea/svg/ea_emitter"
  end
end
