# frozen_string_literal: true

module StoredDiagonalCorner508a37dcHelpers
  def stored_diagonal_corner_508a37dc_output(path)
    document = Ea::Sources::Xmi::Adapter.from_path(path)
    diagram = document.diagrams.first
    connector = diagram.connectors.find do |item|
      item.relationship_ref.include?("1FD0A891_13E7_4818_9498_ACF09C480894")
    end
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document,
      frame: true
    ).render

    [connector, Nokogiri::XML(svg)]
  end
end
