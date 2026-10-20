# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaBridgeOrderHelpers

  it "preserves source placement drawing order and connector placement references" do
    diagram = bridge_order_diagram
    connector = diagram.connectors.first

    expect(diagram.elements.map(&:z_order)).to eq([9, 25])
    expect(connector.source_element_ref).to eq(diagram.elements.first.id)
    expect(connector.target_element_ref).to eq(diagram.elements.last.id)
  end

  it "keeps missing drawing order unresolved, including a saved zero" do
    expect(bridge_order_diagram(sequences: [nil, 0]).elements.map(&:z_order)).to eq([nil, 0])
  end

  it "does not select an ambiguous or missing placement" do
    ambiguous = bridge_order_diagram(source_placements: 2)
    missing = bridge_order_diagram(target_placed: false)

    expect(ambiguous.connectors.first.source_element_ref).to be_nil
    expect(ambiguous.connectors.first.target_element_ref).to eq(ambiguous.elements.last.id)
    expect(missing.connectors.first.source_element_ref).to eq(missing.elements.first.id)
    expect(missing.connectors.first.target_element_ref).to be_nil
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder, "paint order" do
  include QeaBridgeOrderHelpers

  it "records start placement instance id then connector id, unresolved when ambiguous" do
    expect(bridge_order_diagram.connectors.first.paint_order).to eq([10, 1])
    expect(bridge_order_diagram(sequences: [25, 9]).connectors.first.paint_order).to eq([10, 1])
    expect(bridge_order_diagram(source_placements: 2).connectors.first.paint_order).to eq([])
  end
end
