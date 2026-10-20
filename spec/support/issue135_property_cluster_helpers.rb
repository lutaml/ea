# frozen_string_literal: true

module Issue135PropertyClusterHelpers
  GEOMETRY = {
    25 => "SX=19;SY=13;EX=131;EY=13;EDGE=4;$LLB=CX=21:CY=18:OX=-17:OY=2:HDN=0:BLD=0:ITA=0:UND=0:CLR=-" \
           "1:ALN=1:DIR=0:ROT=0;LLT=CX=66:CY=35:OX=2:OY=-36:HDN=0:BLD=0:ITA=0:UND=0:CLR=-1:ALN=1:DIR=0" \
           ":ROT=0;LMT=;LMB=;LRT=;LRB=;IRHS=;ILHS=;",
    89 => "SX=79;SY=-70;EX=91;EY=-173;EDGE=3;$LLB=CX=19:CY=18:OX=-42:OY=16:HDN=0:BLD=0:ITA=0:UND=0:CL" \
           "R=-1:ALN=1:DIR=0:ROT=0;LLT=CX=66:CY=35:OX=163:OY=8:HDN=0:BLD=0:ITA=0:UND=0:CLR=-1:ALN=1:DI" \
           "R=0:ROT=0;LMT=;LMB=;LRT=;LRB=;IRHS=;ILHS=;",
    117 => "EDGE=4;$LLB=CX=21:CY=18:OX=0:OY=0:HDN=0:BLD=0:ITA=0:UND=0:CLR=-1:ALN=1:DIR=0:ROT=0;LLT=CX=" \
           "98:CY=35:OX=62:OY=-27:HDN=0:BLD=0:ITA=0:UND=0:CLR=-1:ALN=1:DIR=0:ROT=0;LMT=;LMB=;LRT=;LRB=" \
           ";IRHS=;ILHS=;"
  }.freeze

  def issue135_property_cluster_geometry(diagram_id)
    GEOMETRY.fetch(diagram_id)
  end

  def issue135_property_cluster(role:, source:, target:, geometry:, **options)
    tables = issue135_property_cluster_tables(role, source, target, geometry, options)
    document = Ea::Sources::Qea::Adapter.new(build_test_database(**tables), "property-cluster.qea").to_document
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false).render
    issue135_property_cluster_positions(Nokogiri::XML(svg).remove_namespaces!, source)
  end

  def issue135_property_cluster_tables(role, source, target, geometry, options)
    tables = qea_end_label_tables("", {}, source, target,
                                  { role: role, mult: "0..1", stereotype: options.fetch(:stereotype, "property") })
    tables.fetch(:objects).each { |object| object.borderwidth = -1 }
    tables.fetch(:objects).last.borderwidth = options.fetch(:target_border, -1)
    tables.fetch(:connectors).first.connector_type = options.fetch(:type, "Association")
    issue135_property_cluster_placements(tables, geometry)
    tables
  end

  def issue135_property_cluster_placements(tables, geometry)
    tables.fetch(:diagram_objects).zip(%w[AAAAAAAA BBBBBBBB]).each do |placement, duid|
      placement.objectstyle = "DUID=#{duid};LWth=2;"
    end
    tables.fetch(:diagram_links).first.geometry = geometry
    tables.fetch(:diagram_links).first.style = "Mode=3;LWidth=2;SOID=AAAAAAAA;EOID=BBBBBBBB;"
  end

  def issue135_property_cluster_positions(xml, source)
    outline = xml.css("rect").find do |rect|
      issue135_property_cluster_numbers(rect, %w[width height]) == source.last(2)
    end
    origin = issue135_property_cluster_numbers(outline, %w[x y])
    qea_label_text_positions(xml).map do |text|
      text.merge(x: text[:x] - origin[0], y: text[:y] - origin[1])
    end
  end

  def issue135_property_cluster_numbers(node, names)
    names.map { |name| node[name].to_f }
  end

  def issue135_property_cluster_control(**options)
    association = Ea::Model::Association.new(id: "association", source_role_name: "extent")
    renderer = issue135_property_cluster_renderer(association, options)
    box = { "ox" => 2, "oy" => -36, "cy" => 35, "alignment" => 1 }.merge(options.fetch(:box, {}))
    texts = renderer.texts(text_box: box, mult_box: nil, anchor: [500, 300],
                           connector: issue135_property_cluster_connector(association, options),
                           end_kind: :source, heading: options.fetch(:heading, [-1, 0]))
    qea_label_text_positions(Nokogiri::XML("<svg>#{texts.join}</svg>"))
  end

  def issue135_property_cluster_connector(association, options)
    Ea::Model::DiagramConnector.new(relationship_ref: association.id, connector_type: "Association",
                                    source_stereotype: options.fetch(:stereotype, "property"),
                                    style: options.fetch(:style, { mode: "3", lwidth: "2" }))
  end

  def issue135_property_cluster_renderer(association, options)
    Ea::Svg::EaEmitter::Label::EndLabel.new(
      canvas: nil, model_index: { association.id => association }, document: nil,
      theme: Ea::Theme::Registry.default, font_family: options.fetch(:family, "Cambria"),
      font_size: options.fetch(:size, 7), font_unit: "pt",
      font_weight: options.fetch(:weight, 400), font_style: options.fetch(:font_style, "normal")
    )
  end
end
