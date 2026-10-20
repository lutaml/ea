# frozen_string_literal: true

module QeaBridgeOrderHelpers
  def bridge_order_diagram(sequences: [9, 25], source_placements: 1, target_placed: true)
    placements = bridge_order_placements(sequences, source_placements, target_placed)
    database = bridge_order_database(placements)
    Ea::Sources::Qea::Adapter.new(database, "bridge-order.qea").to_document.diagrams.first
  end

  def bridge_order_placements(sequences, source_placements, target_placed)
    [1, 2].take(target_placed ? 2 : 1).flat_map do |id|
      Array.new(id == 1 ? source_placements : 1) do |index|
        Ea::Qea::Models::EaDiagramObject.new(
          diagram_id: 1, ea_object_id: id, instance_id: id * 10 + index, sequence: sequences[id - 1],
          rectleft: id * 100, rectright: id * 100 + 80, recttop: 0, rectbottom: -80
        )
      end
    end
  end

  def bridge_order_database(placements)
    rows = Ea::Qea::Models
    build_test_database(
      objects: bridge_order_objects, diagram_objects: placements,
      diagrams: [rows::EaDiagram.new(diagram_id: 1, ea_guid: "bridge-diagram", styleex: "SuppressFOC=1;")],
      connectors: [rows::EaConnector.new(connector_id: 1, ea_guid: "bridge-link", connector_type: "Association",
                                         start_object_id: 1, end_object_id: 2)],
      diagram_links: [rows::EaDiagramLink.new(diagramid: 1, connectorid: 1, instance_id: 1,
                                              style: "Mode=3;", path: "180:-40;200:-40;", hidden: 0)]
    )
  end

  def bridge_order_objects
    [1, 2].map do |id|
      Ea::Qea::Models::EaObject.new(ea_object_id: id, ea_guid: "bridge-object-#{id}",
                                    object_type: "Class", name: "C#{id}")
    end
  end
end
