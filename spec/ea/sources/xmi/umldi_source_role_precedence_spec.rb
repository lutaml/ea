# frozen_string_literal: true

require "spec_helper"

RSpec.describe "0BE declared property source role bounds" do
  include UmldiSourceRolePrecedenceHelpers

  it "preserves authored LLT offsets alongside identified UMLDI bounds and filters stored LLB" do
    connector = source_role_connector
    expect(connector.label_boxes).to include(
      llt: include("ox" => 17, "oy" => -9, "cx" => 57, "cy" => 25),
      llb: include("ox" => 0, "oy" => 0, "cx" => 15, "cy" => 13)
    )
    expect(connector.umldi_label_bounds).to eq(
      source_role: { x: 724, y: 1356, width: 57, height: 25 }
    )
    expect(bounded_by_route(connector)).to eq([[840, 1372], [892, 1225]])
  end

  it "keeps stored extension precedence when the original source property association mismatches" do
    connector = source_role_connector(identity: false)
    expect(connector.label_boxes.fetch(:llt)).to include("ox" => 17, "oy" => -9)
    expect(connector.umldi_label_bounds).to eq({})
    expect(bounded_by_route(connector)).to eq([[840, 1372], [892, 1225]])
  end
end
