# frozen_string_literal: true

require "spec_helper"

RSpec.describe "EA semantic connector dashes" do
  include SemanticConnectorDashHelpers

  it "dashes dependencies and package imports" do
    [["Dependency", nil], %w[Package import]].each do |type, stereotype|
      layers = dash_layers([dash_connector(type, stereotype: stereotype)])
      expect(layers.size).to eq(1)
      expect(layers.first.style).to include("stroke-dasharray:6,3")
    end
  end

  it "keeps other relationship semantics solid" do
    [["Package", nil], %w[Package access], %w[Association import],
     ["Realization", nil], ["Usage", nil]].each do |type, stereotype|
      layers = dash_layers([dash_connector(type, stereotype: stereotype)])
      expect(layers.first.style).not_to include("stroke-dasharray")
      expect(layers.first.style_key).to eq(:connector_line)
    end
  end
end

RSpec.describe "EA semantic connector dash grouping" do
  include SemanticConnectorDashHelpers

  it "separates solid and dashed styles at each explicit pen width" do
    [true, false].each do |grouped|
      records = [2, 4].flat_map do |width|
        [dash_connector("Dependency", width: width),
         dash_connector("Association", width: width)]
      end
      layers = dash_layers(records, grouped: grouped)
      expect(layers.map(&:style_key).uniq.size).to eq(4)
      expect(layers.map(&:style).count { |style| style.include?("stroke-dasharray:6,3") }).to eq(2)
      expect(layers.map(&:style).count { |style| style.include?("stroke-width:4;") }).to eq(2)
      expect(layers.map(&:body).uniq).to eq(['<path d="M 100 0 L 0 0 M 100 0" shape-rendering="auto"/>'])
      expect(records.map { |connector, _relationship| connector.style[:linestyle] }).to eq(["3"] * 4)
    end
  end

  it "groups matching dashed styles together" do
    records = [dash_connector("Dependency"), dash_connector("Package", stereotype: "import")]
    layers = dash_layers(records)
    expect(layers.size).to eq(1)
    expect(layers.first.body.scan("<path").size).to eq(2)
    expect(layers.first.style).to include("stroke-dasharray:6,3")
  end
end
