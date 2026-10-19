# frozen_string_literal: true

require "spec_helper"

RSpec.describe "D32 untreed width-zero horizontal Property target" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers
  include AssociationRayEndLabelHelpers
  include D32HorizontalPropertyEndLabelHelpers

  it "uses the persisted corner and existing leftward Property seat" do
    result = d32_horizontal_labels
    role = result[:texts].find { |text| text[:text] == "+relativeGMLGeometry" }
    stereotype = result[:texts].find { |text| text[:text] == "«property»" }

    expect(result[:first]).to eq([390, 103])
    expect(result[:last]).to eq([405, 103])
    expect([role[:x], role[:y]]).to eq([271, 150])
    expect([stereotype[:x], stereotype[:y]]).to eq([297, 162])
  end

  it "preserves the plain moved box on the same horizontal ray" do
    result = d32_horizontal_labels(stereotype: nil)
    role = result[:texts].find { |text| text[:text] == "+relativeGMLGeometry" }

    expect([role[:x], role[:y]]).to eq([430, 49])
  end
end

RSpec.describe "D32 horizontal Property seat scope" do
  include AssociationRayEndLabelHelpers

  it "preserves adjacent route and box presentations" do
    [{ style: { mode: "2" } }, { style: { lwidth: "1" } }, { style: { tree: "H" } },
     { style: { tree: "LH" } }, { heading: [-10, 1] }, { alignment: 0 }].each do |options|
      text = association_ray_guard_text(stereotype: "property", **options)

      expect(text).to include('x="479.00" y="501.00"')
    end
  end
end
