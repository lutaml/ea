# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.shared_context "QEA constraint diagram" do
  let(:document) { Ea::Sources::Qea::Adapter.from_path("examples/qea/test.qea") }
  let(:diagram) do
    document.diagrams.find { |entry| entry.id.include?("B58D1A53") }
  end
  let(:svg) do
    Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                              document: document).render
  end
  let(:texts) { Nokogiri::XML(svg).remove_namespaces!.xpath("//text") }
  let(:box) do
    Nokogiri::XML(svg).remove_namespaces!.xpath("//rect").find do |node|
      node["width"] == "167" && node["height"] == "112"
    end
  end
end

RSpec.describe "QEA constraint compartments" do
  include_context "QEA constraint diagram"

  it "renders a centered italic caption and left-aligned OCL rows after attributes" do
    caption = texts.find { |node| node.text == "constraints" }
    row = texts.find { |node| node.text == "{pattern}" }
    expect(caption).not_to be_nil
    attributes = texts.select do |node|
      ["string: CharacterString [1..*]", "integer: Integer [0..1]"].include?(node.text) &&
        node["x"].to_f.between?(box["x"].to_f, box["x"].to_f + box["width"].to_f) &&
        node["y"].to_f.between?(box["y"].to_f, caption["y"].to_f)
    end
    attribute = attributes.max_by { |node| node["y"].to_f }
    expect(caption["style"]).to include("font-style:italic")
    expect(caption["y"].to_f).to eq(attribute["y"].to_f + 20)
    expect(row["y"].to_f).to eq(caption["y"].to_f + 12)
    expect(row["x"].to_f).to eq(box["x"].to_f + 5)
    center = caption["x"].to_f + caption["textLength"].to_f / 2
    expect(center).to be_within(0.5).of(box["x"].to_f + box["width"].to_f / 2)
    expect(caption["x"].to_f).to be > row["x"].to_f
  end
end

RSpec.describe Ea::Svg::EaEmitter::Element::CompartmentGeometry, "constraint flow" do
  let(:bounds) { Ea::Model::Bounds.new(x: 10, y: 20, width: 200, height: height) }
  let(:height) { 150 }
  let(:count) { 1 }
  let(:geometry) do
    described_class.new(bounds: bounds, size: 7, header_lines_count: 1, attr_lines_count: 2,
                        op_lines_count: 0, tagged_values_count: 1, constraints_count: count)
  end

  it "places tags after the visible constraint rows" do
    expect(geometry.constraints_first_y).to eq(geometry.attr_bottom_y + 20)
    expect(geometry.tagged_value_first_y).to eq(geometry.constraints_first_y + 24)
  end

  context "without constraints" do
    let(:count) { 0 }

    it "preserves the attribute bottom and tag anchor" do
      expect(geometry.constraints_first_y).to be_nil
      expect(geometry.tagged_value_first_y).to eq(geometry.attr_bottom_y + 12)
    end
  end

  context "when the full constraint compartment cannot fit" do
    let(:height) { 70 }

    it "keeps clipped constraints out of content and tag geometry" do
      expect(geometry.constraints_first_y).to be_nil
      expect(geometry.content_bottom_y).to eq(geometry.attr_bottom_y)
    end
  end
end
