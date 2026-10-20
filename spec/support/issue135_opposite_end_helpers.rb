# frozen_string_literal: true

module Issue135OppositeEndHelpers
  def opposite_end_document(source_role: "lod0MultiSurface", target_role: nil)
    association = Ea::Model::Association.new(
      id: "association", source_id: "surface", target_id: "urban",
      source_role_name: source_role, target_role_name: target_role,
      source_multiplicity_raw: "0..1"
    )
    Ea::Model::Document.new(
      classifiers: opposite_end_classifiers,
      relationships: [association]
    )
  end

  def opposite_end_classifiers
    [Ea::Model::Klass.new(id: "surface", name: "MultiSurface"),
     Ea::Model::Klass.new(id: "urban", name: "_UrbanFunction", properties: [opposite_end_property])]
  end

  def opposite_end_property
    Ea::Model::Property.new(
      id: "member", name: "lod0MultiSurface", association_id: "association",
      owner_id: "urban", type_name: "gml::MultiSurface", visibility: "public",
      multiplicity_raw: "0..1"
    )
  end

  def opposite_end_texts(document, end_kind, stored_labels: true, style: {})
    connector = Ea::Model::DiagramConnector.new(
      id: "connector", relationship_ref: "association", source_stereotype: "property", style: style
    )
    svg = opposite_end_renderer(document).texts(
      text_box: { "ox" => 10, "oy" => 10 }, mult_box: { "ox" => 10, "oy" => 30 },
      anchor: [0, 0], connector: connector, end_kind: end_kind, stored_labels: stored_labels
    ).join
    Nokogiri::XML("<g>#{svg}</g>").css("text").map(&:text)
  end

  def opposite_end_renderer(document)
    Ea::Svg::EaEmitter::Label::EndLabel.new(
      canvas: nil, model_index: document.index_by_id, document: document,
      theme: Ea::Theme::Registry.default, font_family: "Carlito", font_size: 7, font_unit: "pt"
    )
  end
end
