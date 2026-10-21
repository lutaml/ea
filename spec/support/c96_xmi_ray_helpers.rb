# frozen_string_literal: true

require "tempfile"

module C96XmiRayHelpers
  def c96_xmi_document(xml)
    Tempfile.create(["c96-ray", ".xmi"]) do |file|
      file.write(xml)
      file.flush
      return Ea::Sources::Xmi::Adapter.from_path(file.path)
    end
  end

  def c96_render(document)
    diagram = document.diagrams.first
    Nokogiri::XML(Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document,
      frame: true
    ).render)
  end
end
