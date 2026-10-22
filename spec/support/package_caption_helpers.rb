# frozen_string_literal: true

module PackageCaptionHelpers
  def caption_y(compartment, family, size, logical_height: nil)
    context = Ea::Svg::EaEmitter::RenderContext.new(
      bounds: Ea::Model::Bounds.new(x: 400, y: 20, width: 100, height: 80),
      family: family, size: size, size_unit: "pt", logical_height: logical_height,
      theme: Ea::Theme::Registry.default
    )
    svg = compartment.subtitle("(from 3D都市モデル)", context)
    Nokogiri::XML("<svg>#{svg}</svg>").at_css("text")["y"].to_f
  end
end
