# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe "QEA element font fallback" do
  let(:document) { Ea::Sources::Qea::Adapter.from_path("examples/qea/test.qea") }
  let(:diagram) do
    document.diagrams.find do |entry|
      entry.id.casecmp?("B58D1A53-E860-41a3-8352-11C274093E83")
    end
  end

  it "resolves unstored element fonts to the native Cambria default" do
    expect(diagram.elements.map(&:font_family).compact).to be_empty

    families = diagram.elements.map do |element|
      Ea::Svg::EaEmitter::FontResolver.new(diagram).family_for(element)
    end
    expect(families.uniq).to eq(["Cambria"])
  end
end

RSpec.describe "QEA production constraint font" do
  let(:document) { Ea::Sources::Qea::Adapter.from_path("examples/qea/test.qea") }
  let(:diagram) do
    document.diagrams.find { |entry| entry.id.casecmp?("B58D1A53-E860-41a3-8352-11C274093E83") }
  end
  let(:xml) do
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document, frame: true).render
    Nokogiri::XML(svg).remove_namespaces!
  end

  it "renders the native constraint font and offsets without a font override" do
    box = xml.xpath("//rect").find do |node|
      node["width"] == "167" && node["height"] == "112"
    end
    nodes = ["constraints", "{pattern}"].map do |text|
      xml.xpath("//text").find { |node| node.text == text }
    end
    offsets = nodes.map do |node|
      [node["x"].to_f - box["x"].to_f,
       node["y"].to_f - box["y"].to_f]
    end

    expect(offsets).to eq([[61.0, 81.0], [5.0, 93.0]])
    expect(nodes.map { |node| node["style"][/font-family:([^;]+)/, 1] })
      .to eq(%w[Cambria Cambria])
  end
end

RSpec.describe Ea::Svg::EaEmitter::FontResolver do
  it "preserves explicit fonts, inferred stored fonts, and theme defaults" do
    explicit = Ea::Model::DiagramElement.new(id: "explicit", font_family: "Calibri")
    inherited = Ea::Model::DiagramElement.new(id: "inherited")
    stored = Ea::Model::Diagram.new(id: "stored", elements: [explicit, inherited])
    unthemed = described_class.new(stored)
    themed = described_class.new(
      stored, theme: Ea::Theme::Registry.lookup("119")
    )

    expect([unthemed.family_for(explicit), unthemed.family_for(inherited)])
      .to eq(%w[Calibri Calibri])
    expect([themed.family_for(explicit), themed.family_for(inherited)])
      .to eq(%w[Calibri Cambria])
  end
end

RSpec.describe "QEA fallback font connector preservation" do
  it "keeps the native horizontal lateral connector when text uses Cambria" do
    document = Ea::Sources::Qea::Adapter.from_path("examples/qea/test.qea")
    diagram = document.diagrams.find do |entry|
      entry.id.casecmp?("B58D1A53-E860-41a3-8352-11C274093E83")
    end
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document,
      frame: true
    ).render
    paths = Nokogiri::XML(svg).remove_namespaces!.xpath("//path").map { |node| node["d"] }

    expect(paths).to include("M 207 93 L 296 93")
    expect(paths).not_to include("M 207 106 L 296 93")
  end
end

RSpec.describe "Certified lateral line row seating" do
  include ConnectorRedockHelpers

  it "preserves certified lines while retaining ordinary divider seating" do
    [true, false].each do |certified|
      fixture = redock_fixture(
        type: "Association", style: { mode: "3", tree: "LH", derived_lateral_line: certified },
        source: [0, 0, 100, 80], target: [200, 0, 100, 80],
        points: [[100, 40], [200, 40]], anchors: [[100, 40], [200, 40]],
        dividers: { "s" => 40, "t" => 40 }
      )
      pairs = [[100, 40], [200, 40]]
      result = Ea::Svg::EaEmitter::ConnectorRedock.row_slot_adjust(
        pairs, fixture[:diagram].connectors.first, fixture[:diagram],
        fixture[:model_index], fixture[:drawn_bounds], fixture[:divider_y_by_ref]
      )

      expect(result).to eq(certified ? nil : [[100, 53], [200, 53]])
    end
  end
end
