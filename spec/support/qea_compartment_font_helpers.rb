# frozen_string_literal: true

module QeaCompartmentFontHelpers
  def public_compartment_document
    path = File.expand_path("../../examples/qea/20251010_current_plateau_v5.1.qea", __dir__)
    database = cached_qea_database(path)
    Ea::Sources::Qea::Adapter.new(database, path).to_document
  end

  def compartment_texts(document, diagram_id)
    diagram = document.diagrams.find { |entry| entry.id == diagram_id }
    svg = Ea::Svg::EaEmitter::Elements.new(diagram, model_index: document.index_by_id,
                                                    document: document).render
    Nokogiri::XML("<svg>#{svg}</svg>").css("text")
  end
end
