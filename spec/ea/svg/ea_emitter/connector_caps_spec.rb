# frozen_string_literal: true

require "spec_helper"

# EA draws dashed connectors with square caps and round joins; solid
# ones keep round caps and bevel joins. Note links dash at width + 2.
RSpec.describe "EA connector line caps and dashes" do
  def render(connector_type, style: {})
    points = [[100, 60], [300, 60]].map do |x, y|
      Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y))
    end
    connector = Ea::Model::DiagramConnector.new(relationship_ref: "r", connector_type: connector_type,
                                                waypoints: points, style: style)
    Ea::Svg::EaEmitter::Document.new(Ea::Model::Diagram.new(connectors: [connector]),
                                     model_index: { "r" => Ea::Model::Association.new(id: "r") },
                                     content_anchor: false).render
  end

  it "draws a dashed Dependency with square caps, round joins and a 6,3 pattern" do
    svg = render("Dependency")

    expect(svg).to include("stroke-linecap:square;stroke-linejoin:round")
    expect(svg).to include("stroke-dasharray:6,3")
  end

  it "keeps round caps and bevel joins for solid connectors" do
    svg = render("Association")

    expect(svg).to include("stroke-linecap:round;stroke-linejoin:bevel")
    expect(svg).not_to include("stroke-dasharray")
  end

  { 1 => "3,3", 2 => "4,4" }.each do |width, pattern|
    it "dashes a width-#{width} note link as #{pattern}" do
      expect(render("NoteLink", style: { lwidth: width })).to include("stroke-dasharray:#{pattern}")
    end
  end
end
