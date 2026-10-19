# frozen_string_literal: true

require "nokogiri"

module NoteBlankRowHelpers
  def paragraphs(body)
    Ea::Svg::EaEmitter::Compartment::NoteHtml.paragraphs(body).map { |p| [p.text.strip, p.gap] }
  end

  def baselines(body, family: "Arial", size: 9, logical_height: 12)
    context = Ea::Svg::EaEmitter::RenderContext.new(
      bounds: Ea::Model::Bounds.new(x: 0, y: 0, width: 600, height: 300),
      model_element: Ea::Model::Note.new(id: "N1", body: body),
      family: family, size: size, size_unit: "pt", logical_height: logical_height,
      theme: Ea::Theme::Registry.default
    )
    svg = Ea::Svg::EaEmitter::Compartment::NoteBody.render(context)
    Nokogiri::XML.fragment(svg).css("text").map { |row| row["y"].to_f }
  end
end
