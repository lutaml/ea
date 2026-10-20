# frozen_string_literal: true

module XmiLabelBoxHelpers
  def basic_label_box_connectors(diagram_name, relationship_guid)
    [basic_diagram_connector(Ea::Sources::Xmi::Adapter, "spec/fixtures/basic.xmi", diagram_name, relationship_guid),
     basic_diagram_connector(Ea::Sources::Qea::Adapter, "examples/qea/basic.qea", diagram_name, relationship_guid)]
  end

  def basic_diagram_connector(adapter, path, diagram_name, relationship_guid)
    document = QeaBridgeCorpusHelpers.document_for(adapter, File.expand_path("../../#{path}", __dir__))
    diagram = document.diagrams.find { |candidate| candidate.name == diagram_name }
    key = relationship_guid.upcase.tr("-", "_")
    diagram.connectors.find { |connector| connector.relationship_ref.to_s.upcase.tr("-", "_").end_with?(key) }
  end
end
