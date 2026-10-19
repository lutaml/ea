# frozen_string_literal: true

module CompactHeaderRuleHelpers
  class GeometryProbe < Ea::Svg::EaEmitter::Elements
    def source_context(element)
      build_context(element)
    end

    def geometry_for(**options)
      compartment_geometry(Ea::Model::Bounds.new(x: 10, y: 10, width: 200, height: 200),
                           options.delete(:size) || 7, options.delete(:attr_lines) || ["+ value: int"],
                           [], 0, options.delete(:header_lines) || [["Example", :bold]], **options)
    end
  end

  def compact_source_context(file, diagram_prefix, name)
    path = File.expand_path("../../examples/qea/#{file}.qea", __dir__)
    document = Ea::Sources::Qea::Adapter.new(cached_qea_database(path), path).to_document
    compact_document_context(document, diagram_prefix, name)
  end

  def compact_document_context(document, diagram_prefix, name)
    diagram = document.diagrams.find { |entry| entry.id.start_with?(diagram_prefix) }
    element = diagram.elements.find { |entry| document.index_by_id[entry.model_element_ref]&.name == name }
    GeometryProbe.new(diagram, model_index: document.index_by_id, document: document).source_context(element)
  end

  def compact_geometry_control(options = {}, compartments: nil)
    diagram = Ea::Model::Diagram.new(id: "diagram")
    diagram.theme = Ea::Theme::Definition.new(id: "control", compartments: compartments)
    GeometryProbe.new(diagram, model_index: {}).geometry_for(
      classifier: Ea::Model::Klass.new(id: "class", name: "Example"), family: "Cambria", **options
    )
  end
end
