# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA plain target role rendering" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers
  include QeaPlainTargetSeatHelpers
  include QeaCompartmentFontHelpers

  let(:document) { public_compartment_document }

  it "seats both published target roles on their native-exact horizontal routes" do
    [["dc:76:495", "M 323 146 L 456 146", ["369.00", "139.00"]],
     ["dc:106:551", "M 330 107 L 476 107", ["389.00", "100.00"]]].each do |id, path, position|
      xml = public_target_seat_svg(document, id)
      role = xml.css("text").find { |node| node.text == "+lod-1MultiSurface" }

      expect(xml.css("path").map { |node| node["d"] }).to include(path)
      expect([role["x"], role["y"]]).to eq(position)
      expect(role["textLength"]).to eq("84")
      expect(role["style"]).to include("font-family:Cambria", "font-size:7pt")
    end
  end

  it "preserves the published plain source role and its clipped stored ray" do
    xml = public_target_seat_svg(document, "dc:159:751")
    role = xml.css("text").find { |node| node.text == "+developmentProject" }

    expect(xml.css("path").map { |node| node["d"] }).to include("M 791 426 L 656 426")
    expect([role["x"], role["y"], role["textLength"]]).to eq(["685.00", "397.00", "93"])
  end
end

RSpec.describe "QEA plain target label path eligibility" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers
  include QeaPlainTargetSeatHelpers

  it "retains original Path absence independently of generated waypoints" do
    absent = plain_target_seat_connector("")
    saved = plain_target_seat_connector("200:-150;400:-150;")

    expect(absent.style[:plain_target_seat]).to be(true)
    expect(saved.waypoints.size).to eq(2)
    expect(saved.style[:plain_target_seat]).to be_nil
  end
end
