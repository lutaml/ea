# frozen_string_literal: true

module StoredRouteSideEntryHelpers
  def stored_side_entry_route(source:, target:, bend:, style: "Mode=3;TREE=LH;LWidth=2;")
    bounds = ->(values) { Ea::Model::Bounds.new(x: values[0], y: values[1], width: values[2], height: values[3]) }
    described_class.new.waypoints(
      link: described_class::Link.new(style, "stored", nil),
      connector_type: "Generalization",
      source: bounds.call(source),
      target: bounds.call(target),
      bends: [bend],
      offsets: { source: [nil, nil], target: [nil, nil] },
      edge: 1
    )
  end
end
