# frozen_string_literal: true

module XmiCanvasHelpers
  def basic_canvas_document(adapter, path)
    QeaBridgeCorpusHelpers.document_for(adapter, File.expand_path("../../#{path}", __dir__))
  end

  def canvas_view_box(document, diagram_id)
    diagram = document.diagrams.find { |d| d.id.to_s.upcase.tr("_", "-").end_with?(diagram_id) }
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document, frame: true).render
    svg[/viewBox="([^"]*)"/, 1]
  end

  def canvas_diagram(document, diagram_id)
    document.diagrams.find { |d| d.id.to_s.upcase.tr("_", "-").end_with?(diagram_id) }
  end
end
