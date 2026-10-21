# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA legend heading families" do
  include QeaCompartmentFontHelpers
  include LegendSourceDefaultHelpers
  include LegendHeadingFamilyHelpers

  it "keeps the native heading default independent of explicit Calibri item placements" do
    document = public_compartment_document
    %w[8DAB169F-D189-4320-A0F5-4443E3297F0E 5E2C1E2A-82A8-47f4-B2ED-1398D72BFCFD].each do |diagram_id|
      labels, title = public_heading_family_texts(document, diagram_id)

      expect(labels.map { |node| node["style"] }).to all(include("font-family:Calibri;", "font-size:9pt;"))
      expect(title["style"]).to include("font-family:Cambria;", "font-size:12pt;", "font-weight:700;")
      expect(title["textLength"]).to eq("34")
    end
  end
end

RSpec.describe "Legend heading family boundaries" do
  include LegendHeadingFamilyHelpers

  let(:items) { [Ea::Model::LegendItem.new(name: "Classification")] }

  it "preserves the supplied family when the model has no independent heading family" do
    %w[Arial Calibri].each do |family|
      legend = Ea::Model::Legend.new(title: "Legend heading", items: items)
      item, title = heading_family_texts(legend, family: family)

      expect([item["style"], title["style"]]).to all(include("font-family:#{family};"))
    end
  end

  it "uses the independent heading family for emitted text and centering metrics" do
    legend = Ea::Model::Legend.new(title: "Legend heading", heading_family: "Calibri", items: items)
    item, title = heading_family_texts(legend, family: "Arial")
    expected_width = Ea::Fonts::Metrics.text_length("Legend heading", 12, family: "Calibri", weight: 700).round
    centered_x = ((110 + item["x"].to_f + item["textLength"].to_i - expected_width) / 2).floor

    expect(item["style"]).to include("font-family:Arial;", "font-size:9pt;")
    expect(title["style"]).to include("font-family:Calibri;", "font-size:12pt;")
    expect(title["textLength"].to_i).to eq(expected_width)
    expect(title["x"].to_f).to eq(centered_x)
  end
end

RSpec.describe "Legend heading family serialization" do
  include LegendHeadingFamilyHelpers

  let(:items) { [Ea::Model::LegendItem.new(name: "Classification")] }

  it "preserves an explicit heading family through JSON and rendering" do
    legend = Ea::Model::Legend.new(title: "Legend", heading_family: "Arial", items: items)
    restored = Ea::Model::Legend.from_json(legend.to_json)
    item, title = heading_family_texts(restored)

    expect(restored.heading_family).to eq("Arial")
    expect(item["style"]).to include("font-family:Calibri;")
    expect(title["style"]).to include("font-family:Arial;")
  end

  it "retains family inheritance for legacy JSON without heading metadata" do
    legend = Ea::Model::Legend.from_json('{"title":"Legend","items":[{"name":"Item"}]}')
    item, title = heading_family_texts(legend)

    expect([item["style"], title["style"]]).to all(include("font-family:Calibri;"))
  end
end
