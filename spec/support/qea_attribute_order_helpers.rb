# frozen_string_literal: true

module QeaAttributeOrderHelpers
  def qea_attribute_order_document(positions, stereotype: nil)
    rows = Ea::Qea::Models
    database = build_test_database(
      objects: [rows::EaObject.new(ea_object_id: 1, object_type: "Class", name: "C", ea_guid: "class", package_id: 1)],
      packages: [rows::EaPackage.new(package_id: 1, name: "P", ea_guid: "package")],
      attributes: positions.each_with_index.map do |(name, position), index|
        rows::EaAttribute.new(ea_object_id: 1, id: index + 1, name: name, pos: position,
                              ea_guid: "a#{index}", type: "String", stereotype: stereotype)
      end,
      diagrams: [rows::EaDiagram.new(diagram_id: 1, package_id: 1, diagram_type: "Logical", name: "D",
                                     ea_guid: "diagram", cx: 800, cy: 600, styleex: "SuppressFOC=1;")],
      diagram_objects: [rows::EaDiagramObject.new(diagram_id: 1, ea_object_id: 1, instance_id: 1,
                                                  rectleft: 100, rectright: 400, recttop: -100, rectbottom: -400)]
    )
    Ea::Sources::Qea::Adapter.new(database, "attribute-order.qea").to_document
  end

  def rendered_attribute_names(document)
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false).render
    Nokogiri::XML(svg).remove_namespaces!.css("text").map(&:text).select { |text| text.include?(": String") }
  end
end
