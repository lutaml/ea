# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Source Property labels on a saved ray that meets the right face" do
  include LabelHeadingHelpers
  include LabelFacePropertyHelpers

  it "uses the rightward seat although the clipped leg runs back across the box" do
    positions = face_property_positions(right_face_record)

    expect(positions["+lod0Geometry"]).to eq([742, 691])
    expect(positions["«property»"]).to eq([742, 703])
    expect(positions["0..1"]).to eq([742, 713])
  end

  it "keeps the anchor seat without a saved ray and on the top face" do
    plain = face_property_positions(right_face_record, style: { mode: "3", lwidth: "2" })
    top = face_property_positions(top_face_record)

    expect(plain["+lod0Geometry"]).to eq([739, 698])
    expect(top["+lod0Geometry"]).to eq([764, 261])
  end
end
