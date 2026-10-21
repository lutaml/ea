# frozen_string_literal: true

require "spec_helper"

module ConnectorPenHelpers
  def pen_connector(id, line_color: nil, line_width: nil, style: nil)
    Ea::Model::DiagramConnector.new(
      id: id, line_color: line_color, line_width: line_width, style: style,
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 100))
      ]
    )
  end

  def pen_layers(*connectors)
    described_class.new(Ea::Model::Diagram.new(id: "d1", name: "D", connectors: connectors)).layers
  end
end

# Plateau 5DA1E7A7, 73025C5A, C31C1314, E7AABA98: links saved with Color=9204585
# (BGR for #69738C) were stroked black.
RSpec.describe Ea::Svg::EaEmitter::Connectors, "stroke colour" do
  include ConnectorPenHelpers

  it "strokes a link in the colour of its integer line colour" do
    expect(pen_layers(pen_connector("c1", line_color: 9_204_585)).first.style).to include("stroke:#69738C")
  end

  it "reads the colour from the link style when no integer colour is set" do
    layer = pen_layers(pen_connector("c1", style: { color: "9204585" })).first
    expect(layer.style).to include("stroke:#69738C")
  end

  it "keeps black for the default sentinel and for plain links in one layer" do
    layers = pen_layers(pen_connector("c1", line_color: -1), pen_connector("c2", style: { color: "-1" }),
                        pen_connector("c3"))
    expect(layers.size).to eq(1)
    expect(layers.first.style).to include("stroke:#000000")
  end

  it "keeps differently coloured links in separate layers" do
    layers = pen_layers(pen_connector("c1", line_color: 9_204_585), pen_connector("c2"))
    expect(layers.map(&:style_key).uniq.size).to eq(2)
  end
end

# Plateau 9400D9BC and FEBE5726, connector 438: LWidth=0 on the link, IsBold=2 on
# the connector; native draws it two pixels wide. LWidth=0 with IsBold=0 stays one.
RSpec.describe Ea::Svg::EaEmitter::Connectors, "pen width" do
  include ConnectorPenHelpers

  def width_for(link_width, connector_width, default: 2)
    connector = pen_connector("c1", line_width: connector_width, style: link_width && { lwidth: link_width })
    described_class.stroke_width_for(connector, default)
  end

  it "uses the connector's own pen when the link width is zero" do
    expect(width_for("0", 2)).to eq(2)
  end

  it "keeps the one-pixel pen for a zero link width without a connector pen" do
    expect([width_for("0", 0), width_for("0", nil)]).to eq([1, 1])
  end

  it "keeps an explicit link width over the connector pen" do
    expect([width_for("2", 0), width_for("1", 2)]).to eq([2, 1])
  end

  it "falls back to the diagram default for a link without a width" do
    expect(width_for(nil, 2, default: 3)).to eq(3)
  end
end
