# frozen_string_literal: true

require "spec_helper"

RSpec.describe "UMLDI label bounds fallback" do
  let(:fixture_path) { fixtures_path("issue135_route_style/4eb-role-seat-umldi.xmi") }
  let(:fallback) { UmlDiLabelBoundsFallbackHelpers.render_without_extension_boxes(fixture_path) }
  let(:explicit_state) { UmlDiLabelBoundsFallbackHelpers.explicit_box_state(fixture_path) }

  it "uses source bounds only for label boxes omitted from EA extension geometry" do
    expect(fallback[:label_boxes]).to be_empty
    expect(fallback[:bounds]).to include(
      source_role: { x: 970, y: 245, width: 112, height: 25 },
      source_multiplicity: { x: 940, y: 328, width: 15, height: 13 }
    )
    expect(UmlDiLabelBoundsFallbackHelpers.label_position(fallback[:texts], "+indoorOpeningAttribute"))
      .to eq(["185.00", "105.00"])
    expect(UmlDiLabelBoundsFallbackHelpers.label_position(fallback[:texts], "«property»"))
      .to eq(["185.00", "117.00"])
    expect(UmlDiLabelBoundsFallbackHelpers.label_position(fallback[:texts], "0..*"))
      .to eq(["155.00", "188.00"])
    expect(fallback.values_at(:fallback_role_count, :baseline_role_count)).to eq([1, 2])
  end

  it "keeps explicit EA label boxes authoritative for their own end labels" do
    label_boxes, bounds = explicit_state
    expect(label_boxes).to include(:llt, :llb)
    expect(bounds).not_to include(:source_role, :source_multiplicity)
  end
end
