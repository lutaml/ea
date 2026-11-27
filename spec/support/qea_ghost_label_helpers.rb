# frozen_string_literal: true

module QeaGhostLabelHelpers
  def qea_italic_names(document, guid)
    diagram = document.diagrams.find { |entry| entry.id.include?(guid) }
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                    document: document, frame: true).render
    texts = Moxml.parse(svg).xpath("//*[local-name()='text']")
    texts.select { |node| node["style"].to_s.include?("font-style:italic") }.map(&:text)
  end
end
