# frozen_string_literal: true

module D32ExternalSourcePropertyHelpers
  def d32_external_source_labels(**options)
    tables = d32_external_tables(options)
    document = Ea::Sources::Qea::Adapter.new(build_test_database(**tables), "external-source.qea").to_document
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false, content_anchor: false).render
    qea_end_label_result(Nokogiri::XML(svg).remove_namespaces!, "0..1")
  end

  def d32_external_tables(options)
    tables = qea_end_label_tables(options.fetch(:path), { "LRT" => [-26, options.fetch(:offset)], "LRB" => [-54, -85] },
                                  [410, 720, 100, 80], [100, 260, 250, 270],
                                  { role: options.fetch(:role), mult: "0..1",
                                    style: "Mode=3;LWidth=0;SOID=target;EOID=source;" })
    d32_external_placement_ids(tables)
    link = tables.fetch(:diagram_links).first
    dock = "SX=#{options.fetch(:dock_x)};SY=#{options.fetch(:dock_y)};EX=0;EY=0;EDGE=2;"
    link.geometry = link.geometry.sub("SX=0;SY=0;EX=0;EY=0;EDGE=1;", dock)
    tables
  end

  def d32_external_placement_ids(tables)
    tables.fetch(:diagram_objects).zip(%w[source target]).each do |placement, duid|
      placement.objectstyle = "DUID=#{duid};"
    end
  end

  def d32_external_guard_text(**options)
    association = Ea::Model::Association.new(id: "association", source_role_name: "lod1Geometry",
                                             source_multiplicity_raw: options[:mult])
    renderer = d32_external_renderer(association, options)
    arguments = d32_external_arguments(association, options)
    xml = Nokogiri::XML("<svg>#{renderer.texts(**arguments).join}</svg>")
    qea_label_text_positions(xml)
  end

  def d32_external_renderer(association, options)
    Ea::Svg::EaEmitter::Label::EndLabel.new(
      canvas: nil, model_index: { association.id => association }, document: nil,
      theme: Ea::Theme::Registry.default, font_family: options.fetch(:font, "Cambria"),
      font_size: options.fetch(:size, 7), font_unit: "pt"
    )
  end

  def d32_external_arguments(association, options)
    bounds = Ea::Model::Bounds.new(x: 410, y: 720, width: 100, height: 80)
    arguments = { text_box: { "ox" => 0, "oy" => 0, "alignment" => 0 }.merge(options.fetch(:box, {})),
                  mult_box: options[:mult_box], anchor: [501, 685], connector: d32_external_connector(association, options),
                  end_kind: :source, heading: options.fetch(:heading, [-41, -365]) }
    arguments[:source_bounds] = options.fetch(:bounds, bounds) unless options[:omit_bounds]
    arguments
  end

  def d32_external_connector(association, options)
    Ea::Model::DiagramConnector.new(
      relationship_ref: association.id, connector_type: "Association",
      source_stereotype: options[:plain] ? nil : "property",
      style: { mode: "3", lwidth: "0" }.merge(options.fetch(:style, {})),
      source_anchor: options.fetch(:origin, Ea::Model::Point.new(x: 501, y: 685)),
      label_boxes: options.fetch(:boxes, {}), waypoints: d32_external_waypoints
    )
  end

  def d32_external_waypoints
    [[501, 685], [460, 320], [350, 355]].map do |x, y|
      Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y))
    end
  end
end
