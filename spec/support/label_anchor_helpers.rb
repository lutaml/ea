# frozen_string_literal: true

module LabelAnchorHelpers
  def anchor_label_positions(connector, bounds: nil, dividers: nil)
    diagram = Ea::Model::Diagram.new(id: "d", name: "D", connectors: [connector])
    labels = Ea::Svg::EaEmitter::Labels.new(
      diagram, model_index: { "a" => anchor_association }, drawn_bounds: bounds,
               divider_y_by_ref: dividers, theme: anchor_theme
    )
    Nokogiri::XML("<svg>#{labels.render}</svg>").css("text").to_h do |node|
      [node.text, [node["x"].to_f, node["y"].to_f]]
    end
  end

  def anchor_association
    Ea::Model::Association.new(
      id: "a", source_id: "source", target_id: "target",
      source_role_name: "trafficVolumeAttribute", source_multiplicity_raw: "0..1"
    )
  end

  def anchor_theme
    Ea::Theme::Definition.new(id: "anchor", font_size: 7,
                              font_family: "Carlito", font_size_unit: "pt")
  end
end
