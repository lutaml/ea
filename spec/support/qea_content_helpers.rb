# frozen_string_literal: true

require "moxml"

module QeaContentHelpers
  def qea_text_nodes(document, guid)
    diagram = document.diagrams.find { |entry| entry.id.include?(guid) }
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                    document: document, frame: true).render
    Moxml.parse(svg).xpath("//*[local-name()='text']")
  end

  def qea_texts(document, guid)
    qea_text_nodes(document, guid).map(&:text)
  end

  def qea_italic_texts(document, guid)
    qea_text_nodes(document, guid).select { |node| node["style"].to_s.include?("font-style:italic") }.map(&:text)
  end
end
