# frozen_string_literal: true

module RemainingTargetBaselineHelpers
  def remaining_target_baseline_qea
    document = Ea::Sources::Qea::Adapter.new(build_test_database(**remaining_baseline_tables),
                                             "baseline.qea").to_document
    diagram = document.diagrams.first
    labels = Ea::Svg::EaEmitter::Labels.new(diagram, model_index: document.index_by_id,
                                                     document: document, theme: diagram.theme)
    remaining_baseline_positions(labels.render)
  end

  def remaining_baseline_tables
    tables = qea_end_label_tables(nil, { "LRT" => [-5, -2], "LRB" => [0, 0] },
                                  [100, 100, 117, 74], [399, 100, 135, 74],
                                  { end: :target, alignment: 2, role: "role b", mult: "0..1",
                                    stereotype: nil, style: "Mode=3;LWidth=0;" })
    link = tables.fetch(:diagram_links).first
    link.geometry = link.geometry.sub("LRT=CX=19:CY=16", "LRT=CX=34:CY=14")
                        .sub("SX=0;SY=0;EX=0;EY=0;EDGE=1", "SX=1;SY=0;EX=1;EY=0;EDGE=2")
    tables
  end

  def remaining_target_baseline(**options)
    association, connector = remaining_baseline_connector(options)
    presentation = { "ox" => -5, "oy" => -2, "cx" => 34, "cy" => 14,
                     "alignment" => 2 }.merge(options.fetch(:box, {}))
    markup = remaining_baseline_renderer(association, options.fetch(:font, {})).texts(
      text_box: presentation, mult_box: { "ox" => 0, "oy" => 0 }, anchor: options.fetch(:anchor, [399, 137]),
      connector: connector, end_kind: options.fetch(:end_kind, :target),
      heading: options.fetch(:heading, [-182, 0]), stored_labels: true
    ).join
    remaining_baseline_positions(markup)
  end

  def remaining_baseline_connector(options)
    association = Ea::Model::Association.new(id: "baseline", source_role_name: "role b",
                                             target_role_name: "role b", target_multiplicity_raw: "0..1")
    connector = Ea::Model::DiagramConnector.new(
      relationship_ref: association.id, connector_type: options.fetch(:type, "Association"),
      target_stereotype: options[:stereotype], source_stereotype: options[:source_stereotype],
      style: { mode: "3", lwidth: "0", stored_association_ray: true }.merge(options.fetch(:style, {}))
    )
    [association, connector]
  end

  def remaining_baseline_renderer(association, overrides)
    font = { family: "Cambria", size: 7, unit: "pt", weight: 400, style: "normal" }.merge(overrides)
    Ea::Svg::EaEmitter::Label::EndLabel.new(
      canvas: nil, model_index: { association.id => association }, document: nil,
      theme: Ea::Theme::Registry.default, font_family: font[:family], font_size: font[:size],
      font_unit: font[:unit], font_weight: font[:weight], font_style: font[:style]
    )
  end

  def remaining_baseline_positions(markup)
    Nokogiri::XML.fragment(markup).css("text").to_h do |node|
      [node.text, [node["x"].to_f, node["y"].to_f]]
    end
  end
end
