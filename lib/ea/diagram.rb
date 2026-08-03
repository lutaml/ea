# frozen_string_literal: true

module Ea
  # Ea::Diagram holds display-layer helpers shared between sources
  # and emitters. Distinct from Ea::Svg::EaEmitter which produces
  # the standalone SVG output.
  module Diagram
    autoload :DisplayConfig, "ea/diagram/display_config"
  end
end
