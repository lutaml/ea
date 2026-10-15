# frozen_string_literal: true

module QeaConstraintHelpers
  def substitutability_property(value, name: "isSubstitutable", type: "Boolean")
    property = "@PROP=@NAME=#{name}@ENDNAME;@TYPE=#{type}@ENDTYPE;"
    property += "@VALU=#{value}@ENDVALU;" unless value.nil?
    "#{property}@ENDPROP;"
  end

  def qea_constraint_result(description, **xref_attributes)
    xref = Ea::Qea::Models::EaXref.new(
      xref_id: "constraint", name: "CustomProperties", xref_type: "connector property",
      client: "relationship", description: description, **xref_attributes
    )
    result = nil
    render_qea_route(
      path: "150:-250;450:-250;", style: "Mode=3;TREE=V;LWidth=2;", xrefs: [xref],
      connector_attributes: { btm_mid_label: " {isSubstitutable=false} " }
    ) { |document| result = constraint_document_labels(document) }
    result
  end

  def constraint_document_labels(document)
    diagram = document.diagrams.first
    labels = Ea::Svg::EaEmitter::Labels.new(
      diagram, model_index: document.index_by_id, document: document
    )
    { flag: diagram.connectors.first.is_substitutable, svg: labels.render }
  end
end
