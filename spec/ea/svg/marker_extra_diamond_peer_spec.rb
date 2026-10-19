# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Navigable target diamonds" do
  include QeaMarkerHelpers

  it "places an explicitly navigable target arrow at the inner diamond vertex" do
    render_qea_route(path: "M 300,350 L 400,350", style: "",
                     source: [100, 300, 200, 100], target: [400, 300, 200, 100],
                     connector_type: "Aggregation",
                     connector_attributes: { destisaggregate: 2, destisnavigable: 1 }) do |document|
      markup = Ea::Svg::EaEmitter::Markers.new(
        document.diagrams.first, model_index: document.index_by_id
      ).render
      markers = Nokogiri::XML("<svg>#{markup}</svg>")

      expect(markers.xpath("//path").map { |path| path["d"] }).to eq(["M 365 306 L 380 300 L 365 294"])
      expect(markers.at_xpath("//polygon")["points"]).to eq("400 300 390 305 380 300 390 295")
    end
  end

  it "keeps explicitly nonnavigable target diamonds arrowless" do
    geometry = diamond_geometry(connector_type: "Aggregation", destisaggregate: 2,
                                destisnavigable: 0)

    expect(geometry[:arrows]).to eq(0)
    expect(geometry[:tip]).to eq(geometry[:finish])
    expect(geometry[:keys]).to eq(["#000000"])
  end
end

RSpec.describe "Target diamond arrow geometry" do
  include QeaMarkerHelpers

  it "keeps reverse arrows at the source" do
    geometry = diamond_geometry(connector_type: "Aggregation", destisaggregate: 2,
                                destisnavigable: 1, direction: "Destination -> Source")

    expect(geometry[:arrows]).to eq(1)
    expect(geometry[:tip]).to eq(geometry[:finish])
  end

  [[[60, 82], [48, 66], [-12, -16]], [[5, 0], [-15, 0], [-20, 0]]].each do |target, anchor, base|
    it "keeps the terminal direction at the integer inner vertex for target #{target}" do
      connector = Ea::Model::DiagramConnector.new(connector_type: "Aggregation", direction: "Source -> Destination")
      relationship = Ea::Model::Association.new(target_aggregation: "composite", target_navigable: true)
      specs = Ea::Svg::EaEmitter::Marker::Registry.specs_for(
        connector, "Aggregation", [0, 0], target, [0, 0], target, relationship: relationship
      )

      expect(specs.map(&:shape)).to eq(%i[diamond arrow])
      expect(specs.map(&:anchor)).to eq([target, anchor])
      expect(specs.map(&:base)).to eq([[0, 0], base])
    end
  end
end
