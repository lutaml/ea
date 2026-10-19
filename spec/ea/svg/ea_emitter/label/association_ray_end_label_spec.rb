# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA saved-ray association end labels" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers
  include AssociationRayEndLabelHelpers

  it "seats D20 externalReference before its moved target corner" do
    result = render_association_ray_end(role: "externalReference", stereotype: nil,
                                        source: [344, 245, 330, 122], target: [876, 271, 269, 70],
                                        offsets: [-21, -1], dimensions: [99, 16])
    role = result[:texts].find { |text| text[:text] == "+externalReference" }

    expect(result[:last]).to eq([567, 101])
    expect([role[:x], role[:y]]).to eq([458, 93])
  end

  it "seats D31 relativeGMLGeometry at its moved downward target corner" do
    result = render_association_ray_end(role: "relativeGMLGeometry", stereotype: "property",
                                        source: [570, 480, 404, 111], target: [660, 250, 100, 120],
                                        offsets: [0, 8], dimensions: [127, 35],
                                        dock: "SX=68;SY=54;EX=0;EY=0;EDGE=1;")
    role = result[:texts].find { |text| text[:text] == "+relativeGMLGeometry" }
    stereotype = result[:texts].find { |text| text[:text] == "«property»" }

    expect(result[:last]).to eq([220, 160])
    expect([role[:x], role[:y]]).to eq([56, 183])
    expect([stereotype[:x], stereotype[:y]]).to eq([82, 195])
  end
end

RSpec.describe "QEA saved-ray end label preservation" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers
  include AssociationRayEndLabelHelpers

  it "preserves unboxed Property presentation on the same downward saved ray" do
    result = render_association_ray_end(role: "relativeGMLGeometry", stereotype: "property",
                                        source: [570, 480, 404, 111], target: [660, 250, 100, 120],
                                        offsets: [0, 8], dimensions: [127, 16],
                                        dock: "SX=68;SY=54;EX=0;EY=0;EDGE=1;")
    role = result[:texts].find { |text| text[:text] == "+relativeGMLGeometry" }

    expect([role[:x], role[:y]]).to eq([result[:last][0], result[:last][1] - 8])
  end

  it "preserves a zero-offset plain role on a saved ray" do
    result = render_association_ray_end(role: "externalReference", stereotype: nil,
                                        source: [344, 245, 330, 122], target: [876, 271, 269, 70],
                                        offsets: [0, 0], dimensions: [99, 16])
    role = result[:texts].find { |text| text[:text] == "+externalReference" }

    expect([role[:x], role[:y]]).to eq(result[:last])
  end
end

RSpec.describe "Saved-ray label scope" do
  include AssociationRayEndLabelHelpers

  it "preserves moved plain labels outside the saved leftward target contract" do
    [{ style: { mode: "2" } }, { style: { lwidth: "2" } }, { style: { tree: "H" } },
     { style: { stored_association_ray: false } }, { heading: [-10, 1] }, { alignment: 0 }].each do |options|
      text = association_ray_guard_text(**options)

      expect(text).to include('x="479.00" y="501.00"')
    end
  end

  it "preserves moved Property labels outside the downward saved target contract" do
    [{ style: { mode: "2" } }, { style: { lwidth: "2" } }, { style: { tree: "H" } },
     { style: { stored_association_ray: false } }, { heading: [-10, -20] }, { alignment: 0 }].each do |options|
      text = association_ray_guard_text(stereotype: "property", **{ heading: [10, 20] }.merge(options))

      expect(text).to include('x="479.00" y="501.00"')
    end
  end
end
