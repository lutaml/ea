# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA legend text anchors" do
  include TestDatabaseHelper
  include QeaLegendAnchorHelpers

  it "keeps title and item text in the container coordinate frame after canvas translation" do
    [[193, 467], [-100, -200]].each do |left, top|
      xml = rendered_legend_anchor_xml(qea_legend_anchor_document(left: left, top: top))
      container = xml.at_css('rect[rx="3.00"]')
      label = xml.css("text").find { |text| text.text == "Item" }
      title = xml.css("text").find { |text| text.text == "Legend" }

      expect(label["x"].to_f - container["x"].to_f).to eq(32)
      expect(label["y"].to_f - container["y"].to_f).to eq(42)
      expect(title["y"].to_f - container["y"].to_f).to eq(22)
    end
  end

  it "preserves the container and icon geometry and source item color" do
    xml = rendered_legend_anchor_xml(qea_legend_anchor_document(left: 193, top: 467))
    container = xml.at_css('rect[rx="3.00"]')
    icon = xml.at_css('rect[rx="0.00"]')

    expect([container["width"], container["height"]]).to eq(%w[186 95])
    expect([icon["width"], icon["height"]]).to eq(%w[17 17])
    expect(icon["x"].to_f - container["x"].to_f).to eq(10)
    expect(icon["y"].to_f - container["y"].to_f).to eq(30)
    expect(icon.parent["style"]).to include("fill:#CCFFCC")
  end
end
