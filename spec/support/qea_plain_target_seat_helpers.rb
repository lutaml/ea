# frozen_string_literal: true

module QeaPlainTargetSeatHelpers
  def public_target_seat_svg(document, instance_id)
    diagram = document.diagrams.find { |entry| entry.connectors.any? { |connector| connector.id == instance_id } }
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document, frame: true).render
    Nokogiri::XML(svg)
  end

  def plain_target_seat_connector(path)
    tables = qea_end_label_tables(path, { "LRT" => [0, 0] }, [100, 100, 100, 100], [400, 100, 100, 100],
                                  { end: :target, role: "lod-1MultiSurface", mult: "0..1", stereotype: nil })
    database = build_test_database(**tables)
    document = Ea::Sources::Qea::Adapter.new(database, "target-seat.qea").to_document
    document.diagrams.first.connectors.first
  end
end
