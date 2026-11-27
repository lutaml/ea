# frozen_string_literal: true

module Issue135X7cGapHelpers
  def x7c_svg(corpus, guid)
    path = File.expand_path("../../examples/qea/#{corpus}.qea", __dir__)
    document = Ea::Sources::Qea::Adapter.new(cached_qea_database(path), path).to_document
    diagram = document.diagrams.find { |entry| entry.id.to_s.upcase.start_with?(guid) }
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document).render
    Moxml.parse(svg)
  end

  def x7c_text_at(xml, text, row: nil)
    xml.xpath("//*[local-name()='text']").select { |node| node.content == text && (row.nil? || node["y"] == row) }
       .map { |node| [node["x"], node["y"]] }
  end
end
