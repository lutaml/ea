# frozen_string_literal: true

module SignalHeaderHelpers
  include QeaCompartmentFontHelpers

  def signal_document(file)
    path = File.expand_path("../../examples/qea/#{file}.qea", __dir__)
    Ea::Sources::Qea::Adapter.new(cached_qea_database(path), path).to_document
  end

  def signal_header_rows(document, name)
    diagram, placement = signal_placement(document, name)
    yield placement if block_given?
    texts = compartment_texts(document, diagram.id)
    stereotype = signal_stereotype(texts, placement.bounds)
    [stereotype, texts.find { |text| text.text == name }].map do |text|
      text["y"].to_f - placement.bounds.y
    end
  end

  def signal_placement(document, name)
    model = document.index_by_id.values.find { |entry| entry.name == name }
    diagram = document.diagrams.find do |entry|
      entry.elements.any? { |element| element.model_element_ref == model.id }
    end
    [diagram, diagram.elements.find { |element| element.model_element_ref == model.id }]
  end

  def signal_stereotype(texts, bounds)
    center = bounds.x + bounds.width / 2
    texts.select { |text| text.text == "«signal»" }.min_by do |text|
      (text["x"].to_f + text["textLength"].to_f / 2 - center).abs
    end
  end
end
