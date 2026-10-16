# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "QEA compartment fonts" do
  include QeaCompartmentFontHelpers

  let(:document) { public_compartment_document }

  it "uses Cambria cells for attributes without a stored font override" do
    texts = compartment_texts(document, "0114FD24-9E58-4664-98CD-71305B59AD11")
    rows = texts.select { |node| node.text.start_with?("geometrySrcDescLod") }

    # Published SVG positions are model coordinates + (3, 2).
    expect(rows.map { |node| [node["x"].to_f + 3, node["y"].to_f + 2] })
      .to eq([[358, 398], [358, 410], [358, 422], [358, 434], [358, 446]])
    expect(rows.map { |node| node["style"] }).to all(include("font-family:Cambria;", "font-size:7pt;"))
  end

  it "preserves explicit default-marker fonts at both published point sizes" do
    records = [
      ["BC1F7E00-082D-4a26-922B-3967A8D66859", "theme:", [[242, 187]], "7pt"],
      ["0016F797-D055-4717-AF1A-606413D0A166", "sectionID:", [[496, 995]], "9pt"],
      ["0016F797-D055-4717-AF1A-606413D0A166", "routeName:", [[496, 1010]], "9pt"]
    ]
    records.each do |diagram_id, prefix, positions, size|
      rows = compartment_texts(document, diagram_id).select { |node| node.text.start_with?(prefix) }

      expect(rows.map { |node| [node["x"].to_f, node["y"].to_f] }).to eq(positions)
      expect(rows.map { |node| node["style"] }).to all(include("font-family:Carlito;", "font-size:#{size};"))
    end
  end
end

RSpec.describe "QEA classifier font inheritance" do
  include QeaCompartmentFontHelpers

  let(:document) { public_compartment_document }

  it "inherits a classifier font when its placement stores use-default markers" do
    diagram = document.diagrams.find { |entry| entry.id == "01661E1B-31B6-4167-BCCF-A00678FB4EA2" }
    placement = diagram.elements.find do |entry|
      document.index_by_id[entry.model_element_ref]&.name == "_UrbanFunction"
    end
    expect([placement.font_family, placement.font_size]).to eq(["Yu Gothic UI", 9])

    rows = compartment_texts(document, diagram.id).select do |node|
      node.text.start_with?("class:", "function:", "usage:")
    end
    expect(rows.map { |node| node["y"].to_f }.each_cons(2).map { |a, b| b - a })
      .to eq([15, 15])
    expect(rows.map { |node| node["style"] }).to all(include("font-family:Carlito;", "font-size:9pt;"))
  end
end

RSpec.describe "QEA font size units" do
  include QeaCompartmentFontHelpers

  let(:document) { public_compartment_document }

  it "keeps QEA point sizes when the diagram theme has pixel defaults" do
    texts = compartment_texts(document, "38170608-32B5-4a6f-A68D-A0D7C0C9D019")
    rows = texts.select { |node| node.text.start_with?("class:", "function:", "usage:") }

    expect(rows).not_to be_empty
    expect(rows.map { |node| node["style"] }).to all(include("font-size:9pt;"))
  end
end
