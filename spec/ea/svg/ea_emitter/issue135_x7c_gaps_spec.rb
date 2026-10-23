# frozen_string_literal: true

require "spec_helper"
require "ea"

# Positions below are the values EA's own export draws for the same
# diagrams in the repository's small example models.
RSpec.describe "issue 135 small-corpus gaps (QEA)" do # rubocop:disable Metrics/BlockLength
  include FixtureCache
  include Issue135X7cGapHelpers

  it "seats an ALN=2 role on a leftward target 2px short of its corner (basic 6E95B74E)" do
    xml = x7c_svg("basic", "6E95B74E")

    expect(x7c_text_at(xml, "+role b")).to eq([%w[272.00 38.00]])
  end

  it "seats ALN=0 and rightward ALN=2 roles of basic D351FC34" do
    xml = x7c_svg("basic", "D351FC34")

    expect(x7c_text_at(xml, "+roleTwo")).to eq([%w[243.00 32.00]])
    expect(x7c_text_at(xml, "+roleOne")).to eq([%w[154.00 34.00]])
  end

  it "seats an ALN=2 source role of an aggregation 2px before its corner (basic 6D0349D5)" do
    expect(x7c_text_at(x7c_svg("basic", "6D0349D5"), "+role b")).to eq([%w[230.00 35.00]])
  end

  it "keeps the bare 10 canvas margin below a nested class of the own package (basic 6D0349D5)" do
    expect(x7c_svg("basic", "6D0349D5").at_css("svg")["viewBox"]).to eq("0 0 528 250")
  end

  it "starts a name wider than its box 2px inside the left edge (simple 204F4ACC)" do
    expect(x7c_text_at(x7c_svg("simple", "204F4ACC"), "AcmeUmlEnumeration")).to eq([%w[42.00 65.00]])
  end

  it "grows a tags-only box to hold its tagged values (simple 204F4ACC)" do
    rect = x7c_svg("simple", "204F4ACC").css("rect").find { |node| node["x"] == "10" && node["y"] == "10" }

    expect(rect["height"]).to eq("85")
  end

  context "with the unthemed test B58D1A53 diagram" do
    let(:xml) { x7c_svg("test", "B58D1A53") }

    it "draws connector labels in Cambria 7pt, not the Yu Gothic UI fallback" do
      labels = xml.css("text").select { |node| %w[+role1 +role2].include?(node.text) }

      expect(labels.map { |node| node["style"][/font-family:([^;]*);/, 1] }).to eq(%w[Cambria Cambria])
      expect(xml.css("text").map { |node| node["style"].to_s }).not_to include(a_string_matching(/Yu Gothic UI/))
    end

    it "seats the zero-offset lateral roles on the native positions" do
      expect(x7c_text_at(xml, "+role1")).to eq([%w[185.00 56.00]])
      expect(x7c_text_at(xml, "+role2")).to eq([%w[239.00 56.00]])
      expect(x7c_text_at(xml, "1")).to eq([%w[262.00 78.00]])
    end

    it "draws plain attributes before stereotyped ones" do
      expect(x7c_text_at(xml, "union: Union")).to eq([%w[292.00 68.00]])
      expect(x7c_text_at(xml, "«voidable»")).to eq([%w[283.00 84.00]])
    end

    it "puts the enumeration divider 7px under the name" do
      expect(xml.css("path").map { |node| node["d"] }).to include("M 261 346 L 350 346")
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Label::PlainTargetSeat, ".unmoved_lateral_role?" do
  let(:connector) { Struct.new(:connector_type, :style) }
  let(:box) { { "alignment" => 0, "cy" => 13, "ox" => 0, "oy" => 0 } }

  it "accepts a QEA derived lateral line" do
    style = { mode: "3", lwidth: "0", tree: "LH", derived_lateral_line: true }

    expect(described_class.unmoved_lateral_role?(connector.new("Association", style), box)).to be(true)
  end

  it "accepts the XMI UMLDI-routed equivalent (test B58D1A53)" do
    style = { mode: "3", lwidth: "0", tree: "LH", umldi_route: true }

    expect(described_class.unmoved_lateral_role?(connector.new("Association", style), box)).to be(true)
  end

  it "rejects a moved box and an unrouted style" do
    style = { mode: "3", lwidth: "0", tree: "LH", umldi_route: true }

    moved = box.merge("ox" => 4)
    unrouted = connector.new("Association", style.except(:umldi_route))

    expect(described_class.unmoved_lateral_role?(connector.new("Association", style), moved)).to be(false)
    expect(described_class.unmoved_lateral_role?(unrouted, box)).to be(false)
  end
end
