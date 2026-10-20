# frozen_string_literal: true

require "spec_helper"

RSpec.describe "0BE absent and stored zero extension labels" do
  include Xmi0beLabelPrecedenceHelpers

  let(:saved) { bounded_by_connector }

  it "keeps authored UMLDI labels instead of manufacturing phantom offsets" do
    expect(saved.label_boxes).to eq({})
    expect(saved.umldi_label_bounds).to eq(
      source_role: { x: 724, y: 1356, width: 57, height: 25 },
      source_multiplicity: { x: 843, y: 1356, width: 15, height: 13 }
    )
  end

  it "retains real zero LLT and only falls back for omitted multiplicity" do
    connector = bounded_by_connector(box: "LLT")
    expect(connector.label_boxes.fetch(:llt)).to include("ox" => 0, "oy" => 0)
    expect(connector.umldi_label_bounds).to eq(
      source_multiplicity: { x: 843, y: 1356, width: 15, height: 13 }
    )
    expect(bounded_by_route(connector)).to eq([[840, 1372], [892, 1225]])
  end

  it "retains real zero LLB and only falls back for omitted role" do
    connector = bounded_by_connector(box: "LLB")
    expect(connector.label_boxes.fetch(:llb)).to include("ox" => 0, "oy" => 0)
    expect(connector.umldi_label_bounds).to eq(
      source_role: { x: 724, y: 1356, width: 57, height: 25 }
    )
    expect(bounded_by_route(connector)).to eq([[840, 1372], [892, 1225]])
  end
end

RSpec.describe "0BE phantom label fallback" do
  include Xmi0beLabelPrecedenceHelpers

  let(:saved) { bounded_by_connector }

  it "preserves phantom zero offsets when no saved UMLDI labels exist" do
    connector = bounded_by_connector(remove_bounds: true)
    expect(connector.label_boxes).to eq(llb: { "ox" => 0, "oy" => 0 },
                                        llt: { "ox" => 0, "oy" => 0 })
    expect(connector.umldi_label_bounds).to eq({})
    expect(bounded_by_route(connector)).to eq(bounded_by_route(saved))
  end
end
