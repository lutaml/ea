# frozen_string_literal: true

module AssociationRayEndLabelHelpers
  def render_association_ray_end(**options)
    database = build_test_database(**association_ray_end_tables(options))
    document = Ea::Sources::Qea::Adapter.new(database, "association-ray.qea").to_document
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false).render
    qea_end_label_result(Nokogiri::XML(svg).remove_namespaces!, "0..1")
  end

  def association_ray_end_tables(options)
    tables = qea_end_label_tables(nil, { "LRT" => options.fetch(:offsets), "LRB" => [0, 0] },
                                  options.fetch(:source), options.fetch(:target),
                                  { end: :target, alignment: 1, role: options.fetch(:role), mult: "0..1",
                                    stereotype: options[:stereotype], style: "Mode=3;LWidth=0;" })
    link = tables.fetch(:diagram_links).first
    link.geometry = association_ray_end_geometry(link.geometry, options)
    tables
  end

  def association_ray_end_geometry(geometry, options)
    width, height = options.fetch(:dimensions)
    dock = options.fetch(:dock, "SX=1;SY=0;EX=1;EY=0;EDGE=2;")
    geometry.sub(/\ASX=.*?\$/, "#{dock}$")
            .sub("LRT=CX=19:CY=16", "LRT=CX=#{width}:CY=#{height}")
  end

  def association_ray_guard_style(style)
    { mode: "3", lwidth: "0", stored_association_ray: true }.merge(style)
  end

  def association_ray_guard_text(style: {}, heading: [-10, 0], alignment: 1, stereotype: nil)
    association = Ea::Model::Association.new(id: "association", target_role_name: "member")
    connector = Ea::Model::DiagramConnector.new(relationship_ref: association.id, connector_type: "Association",
                                                target_stereotype: stereotype,
                                                style: association_ray_guard_style(style))
    renderer = Ea::Svg::EaEmitter::Label::EndLabel.new(canvas: nil, model_index: { association.id => association },
                                                       document: nil, theme: Ea::Theme::Registry.default,
                                                       font_family: "Cambria", font_size: 7, font_unit: "pt")
    box = { "ox" => -21, "oy" => -1, "alignment" => alignment, "cy" => stereotype ? 35 : 16 }
    renderer.texts(text_box: box, mult_box: nil, anchor: [500, 500], connector: connector, end_kind: :target,
                   heading: heading).join
  end
end
