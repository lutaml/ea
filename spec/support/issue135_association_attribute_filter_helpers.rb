# frozen_string_literal: true

module Issue135AssociationAttributeFilterHelpers
  def issue135_attribute_filter_document
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(source_format: "xmi"),
      classifiers: issue135_attribute_filter_classifiers,
      relationships: [Ea::Model::Association.new(id: "drawn-association", source_id: "zone", target_id: "boundary")],
      diagrams: [issue135_attribute_filter_diagram]
    )
  end

  def issue135_attribute_filter_classifiers
    [issue135_attribute_filter_zone,
     Ea::Model::Klass.new(id: "facility", name: "UrbanFacility", properties: [
                            Ea::Model::Property.new(id: "facility-name", name: "name", type_name: "String"),
                            issue135_association_property("threeDimensionalExtent", "ThreeDimensionalExtent",
                                                          "extent-association")
                          ]),
     Ea::Model::Klass.new(id: "boundary", name: "Boundary")]
  end

  def issue135_attribute_filter_zone
    Ea::Model::Klass.new(id: "zone", name: "Zone", properties: [
                           Ea::Model::Property.new(id: "ordinary", name: "boundary", type_name: "String"),
                           issue135_association_property("boundary", "Boundary", "boundary-association"),
                           issue135_association_property("urbanParkAttribute", "UrbanParkAttribute",
                                                         "park-association"),
                           issue135_association_property("drawnBoundary", "Boundary", "drawn-association")
                         ])
  end

  def issue135_attribute_filter_diagram
    Ea::Model::Diagram.new(id: "diagram", name: "Association attributes", elements: [
                             issue135_attribute_filter_placement("zone", 10, 10),
                             issue135_attribute_filter_placement("facility", 10, 300),
                             issue135_attribute_filter_placement("boundary", 400, 10)
                           ], connectors: [issue135_attribute_filter_connector])
  end

  def issue135_attribute_filter_connector
    Ea::Model::DiagramConnector.new(
      id: "drawn", relationship_ref: "drawn-association", connector_type: "Association",
      source_element_ref: "placed-zone", target_element_ref: "placed-boundary",
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 250, y: 100)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 400, y: 100))
      ], label_boxes: { llt: { "ox" => 10, "oy" => 15 }, llb: { "ox" => 10, "oy" => 30 } }
    )
  end

  def issue135_association_property(name, type, association_id)
    Ea::Model::Property.new(id: "property-#{association_id}", name: name, type_name: type,
                            association_id: association_id, visibility: "public",
                            multiplicity_lower: 0, multiplicity_upper: -1)
  end

  def issue135_attribute_filter_placement(identifier, left, top)
    Ea::Model::DiagramElement.new(id: "placed-#{identifier}", model_element_ref: identifier,
                                  bounds: Ea::Model::Bounds.new(x: left, y: top, width: 240, height: 200))
  end

  def issue135_attribute_filter_texts(document)
    emitter = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, document: document,
                                                                        model_index: document.index_by_id, frame: false, content_anchor: false)
    svg = emitter.render
    Nokogiri::XML(svg).remove_namespaces!.css("text").map(&:text)
  end
end
