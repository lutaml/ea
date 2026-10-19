# frozen_string_literal: true

module TagCaptionCenteringHelpers
  def tag_caption_nodes(width: 100, family: "Cambria", size: 7,
                        size_unit: "pt", logical_height: nil)
    svg = Ea::Svg::EaEmitter::Element::TaggedValueRenderer.render(
      [Ea::Model::TaggedValue.new(key: "HighPrecision", value: "false")],
      bounds: Ea::Model::Bounds.new(x: 10, y: 20, width: width, height: 200),
      first_y: 50, family: family, size: size, size_unit: size_unit,
      logical_height: logical_height
    )
    Nokogiri::XML("<svg>#{svg}</svg>").css("text")
  end

  def arcgis_tag_caption_nodes
    path = File.expand_path("../../examples/qea/ArcGISWorkspace_template.qea", __dir__)
    document = Ea::Sources::Qea::Adapter.new(cached_qea_database(path), path).to_document
    diagram = document.diagrams.find { |entry| entry.id == "7C44AC09-27C1-47b3-9A85-88EC71C081FF" }
    trailing_public_text_nodes(document, diagram).select do |node|
      node.text == "tags" || node.text.include?(" = ")
    end
  end
end
