# frozen_string_literal: true

module PlainSourceSeatHelpers
  def assert_plain_source_seat_controls(record, box, options)
    plain_source_seat_controls(box).each do |control|
      positions = upward_property_positions(record, **options, **control.reject { |key, _| key == :expected })

      expect(positions["+developmentProject"]).to eq(control.fetch(:expected, [960, 558])), control.inspect
    end
  end

  def plain_source_seat_controls(box)
    [
      { style: { mode: "3", lwidth: "2" } }, { type: "Association" },
      { box: box.merge("ox" => 0, "oy" => 0), expected: [970, 536] },
      { style: { mode: "3", lwidth: "0" } },
      { style: { mode: "2", lwidth: "2" } }, { style: { mode: "3", lwidth: "2", tree: "V" } },
      { heading: [-135, 1] }, { family: "Carlito" }, { size: 8 }, { unit: "px" },
      { box: box.merge("cy" => 35) }, { box: box.merge("bold" => true) },
      { box: box.merge("rotation" => 90) }, { box: box.merge("color" => 255) },
      { box: box.merge("alignment" => 2) }, { stereotype: "Type" }
    ]
  end

  def plain_source_seat_result(path: "", **options)
    database = build_test_database(**plain_source_seat_tables(path, options))
    document = Ea::Sources::Qea::Adapter.new(database, "plain-seat.qea").to_document
    diagram = document.diagrams.first
    connector = diagram.connectors.first
    canvas = Ea::Svg::EaEmitter::Canvas.from(diagram, model_index: document.index_by_id)
    labels = Ea::Svg::EaEmitter::Labels.new(diagram, canvas: canvas, model_index: document.index_by_id,
                                                     document: document, theme: diagram.theme)
    { connector: connector, offset: plain_source_role_offset(labels, connector, canvas) }
  end

  def plain_source_seat_tables(path, options)
    tables = qea_end_label_tables(path, { "LLT" => [-10, -22] },
                                  [971, 483, 250, 105], [616, 513, 218, 70],
                                  { role: "developmentProject", mult: "0..*", stereotype: nil, alignment: 1 })
    tables[:connectors].first.connector_type = options.fetch(:type, "Aggregation")
    link = tables[:diagram_links].first
    link.style = options.fetch(:style, "Mode=3;LWidth=2;")
    link.geometry = link.geometry.sub("CY=16", "CY=18")
    tables
  end

  def plain_source_role_offset(labels, connector, canvas)
    anchor = labels.send(:label_points, connector).first
    texts = Nokogiri::XML("<svg>#{labels.send(:texts_for, connector).join}</svg>")
    role = texts.css("text").find { |node| node.text == "+developmentProject" }
    plain_source_qea_position(role, canvas).zip(anchor).map { |value, origin| value - origin }
  end

  def plain_source_qea_position(role, canvas)
    [role["x"].to_f + canvas.min_x - canvas.inset_left,
     role["y"].to_f + canvas.min_y - 40]
  end
end
