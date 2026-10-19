# frozen_string_literal: true

require "spec_helper"
require "ea"
require "nokogiri"

RSpec.shared_context "package tab renderer" do
  let(:renderer) { Ea::Svg::EaEmitter::Element::PackageShapeRenderer }
  let(:bounds) { Ea::Model::Bounds.new(x: 35, y: 60, width: 154, height: 102) }
  let(:paint) { { fill: "#FFFFFF", stroke: "#000000", stroke_width: 1 } }
end

RSpec.describe "Package tab font row heights" do
  include_context "package tab renderer"

  it "sizes each tab row using the existing font line height", :aggregate_failures do
    [
      ["Cambria", 7, nil, 19, [73]],
      ["Cambria", 7, "Type", 34, [73, 85]],
      ["Carlito", 9, nil, 22, [75]],
      ["Carlito", 9, "Type", 40, [75, 90]]
    ].each do |family, size, stereotype, height, baselines|
      svg = renderer.render(bounds, **paint, label: "Schema", family: family,
                                             size: size, stereotype: stereotype)
      nodes = Nokogiri::XML(svg)
      polygons = nodes.css("polygon").map { |node| node["points"].split.map(&:to_f) }

      expect(polygons).to eq([
                               [35, 60 + height, 189, 60 + height, 189, 162, 35, 162, 35, 60 + height],
                               [35, 60, 140, 60, 140, 60 + height, 35, 60 + height, 35, 60]
                             ])
      expect(nodes.css("text").map { |text| text["y"].to_f }).to eq(baselines)
      expect(nodes.css("text").map { |text| text["x"].to_f }).to eq([40] * baselines.length)
      expect(nodes.at_css("g")["style"])
        .to eq("stroke-width:1;stroke-linecap:round;stroke-linejoin:bevel; " \
               "fill:#FFFFFF;fill-opacity:1.00; stroke:#000000; stroke-opacity:1.00")
    end
  end
end

RSpec.describe "Default package tab heights" do
  include_context "package tab renderer"

  it "preserves default font sizing and the nominal package padding" do
    [[nil, 20, [73]], ["Type", 36, [73, 86]]].each do |stereotype, height, baselines|
      svg = renderer.render(bounds, **paint, label: "Schema", stereotype: stereotype)
      nodes = Nokogiri::XML(svg)
      body, tab = nodes.css("polygon").map { |node| node["points"].split.map(&:to_f) }

      expect(tab).to eq([35, 60, 140, 60, 140, 60 + height, 35, 60 + height, 35, 60])
      expect(body).to eq([35, 60 + height, 189, 60 + height, 189, 162, 35, 162, 35, 60 + height])
      expect(nodes.css("text").map { |text| text["y"].to_f }).to eq(baselines)
    end
  end
end

RSpec.describe "Pixel-unit package tab heights" do
  include_context "package tab renderer"

  it "preserves fixed tab geometry and baselines for pixel font units" do
    [["Cambria", 7], ["Carlito", 9], ["Carlito", 16]].each do |family, size|
      [[nil, 20, [73]], ["Type", 36, [73, 86]]].each do |stereotype, height, baselines|
        svg = renderer.render(bounds, **paint, label: "X", family: family,
                                               size: size, size_unit: "px", stereotype: stereotype)
        nodes = Nokogiri::XML(svg)
        body, tab = nodes.css("polygon").map { |node| node["points"].split.map(&:to_f) }

        expect(tab).to eq([35, 60, 140, 60, 140, 60 + height, 35, 60 + height, 35, 60])
        expect(body).to eq([35, 60 + height, 189, 60 + height, 189, 162, 35, 162, 35, 60 + height])
        expect(nodes.css("text").map { |text| text["y"].to_f }).to eq(baselines)
      end
    end
  end
end

RSpec.describe "Public QEA package tab heights" do
  include QeaCompartmentFontHelpers

  let(:document) { public_compartment_document }

  it "matches the Cambria and Carlito source package tab boundaries", :aggregate_failures do
    [
      ["2A5E0832-06BE-4381-85D4-9B00E4F95575", { "tran" => 19, "uro" => 34 }],
      ["37AC19B9-8433-4fee-A326-763170D54D06", { "都市計画基本図" => 22 }],
      ["DFBB1072-8EC5-4384-8241-7EDF4B6B888B", { "CityGML2.0" => 40 }]
    ].each do |id, expected|
      diagram = document.diagrams.find { |entry| entry.id == id }
      svg = Ea::Svg::EaEmitter::Elements.new(diagram, model_index: document.index_by_id,
                                                      document: document).render
      nodes = Nokogiri::XML("<svg>#{svg}</svg>")
      expected.each do |name, height|
        titles = nodes.css("text").select { |text| text.text == name }
        expect(titles.length).to eq(1)
        body, tab = titles.first.parent.css("polygon").map do |polygon|
          polygon["points"].split.map(&:to_f)
        end

        expect(tab.length).to eq(10)
        expect(tab[5] - tab[1]).to eq(height)
        expect(body[1]).to eq(tab[5])
      end
    end
  end
end
