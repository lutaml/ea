# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.shared_context "stored midpoint stereotype" do
  let(:relationship) do
    Ea::Model::Dependency.new(id: "import", client_id: "a", supplier_id: "b", stereotype: "import")
  end
  let(:stored_box) do
    geometry = "$LMB=CX=54:CY=18:OX=0:OY=0:HDN=0:BLD=0:ITA=0:UND=0:CLR=-1:ALN=1:DIR=0:ROT=0;"
    Ea::Sources::Qea::DiagramBuilder.new(nil).parse_label_boxes(geometry).fetch(:lmb)
  end
  let(:connector) do
    Ea::Model::DiagramConnector.new(id: "import-seat", relationship_ref: relationship.id,
                                    label_boxes: { lmb: stored_box })
  end
  let(:renderer) do
    described_class.new(canvas: nil, model_index: { relationship.id => relationship },
                        font_family: "Cambria", font_size: 7, font_unit: "pt")
  end
end

RSpec.describe Ea::Svg::EaEmitter::Label::MidpointLabel, "centered bottom seats" do
  include_context "stored midpoint stereotype"

  it "places the plateau 49 centered import in the stored bottom midpoint seat" do
    output = renderer.text_for(connector, [[443, 179], [443, 120]])
    text = Nokogiri::XML(output).at_xpath("//text")

    expect([text["x"].to_f, text["y"].to_f, text.text]).to eq([424, 162, "«import»"])
  end

  it "applies stored offsets and measured widths independently of the route heading" do
    stored_box.merge!("ox" => 8, "oy" => -5)
    relationship.stereotype = "realize"
    output = renderer.text_for(connector, [[100, 50], [100, 150]])
    text = Nokogiri::XML(output).at_xpath("//text")
    width = Ea::Fonts::Metrics.text_length("«realize»", 7, family: "Cambria")

    expect([text["x"].to_f, text["y"].to_f, text.text])
      .to eq([108 - (width / 2.0).floor, 108, "«realize»"])
  end
end

RSpec.describe Ea::Svg::EaEmitter::Label::MidpointLabel, "native CY13 bottom seats" do
  include_context "stored midpoint stereotype"

  let(:stored_box) do
    geometry = "$LMB=CX=44:CY=13:OX=0:OY=0:HDN=0:BLD=0:ITA=0:UND=0:CLR=-1:ALN=1:DIR=0:ROT=0;"
    Ea::Sources::Qea::DiagramBuilder.new(nil).parse_label_boxes(geometry).fetch(:lmb)
  end

  it "places the CY13 basic 4 and plateau 78 imports below their stored route midpoints" do
    controls = [
      [[[165, 80], [261, 80]], [194, 93]],
      [[[218, 120], [143, 190]], [161, 168]],
      [[[309, 120], [393, 190]], [332, 168]]
    ]
    controls.each do |points, expected|
      text = Nokogiri::XML(renderer.text_for(connector, points)).at_xpath("//text")

      expect([text["x"].to_f, text["y"].to_f]).to eq(expected), points.inspect
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Label::MidpointLabel, "unsupported box presentations" do
  include_context "stored midpoint stereotype"

  it "preserves midpoint placement for unsupported box presentations" do
    controls = [nil, stored_box.merge("alignment" => 0), stored_box.merge("rotation" => 30),
                stored_box.merge("hidden" => true), stored_box.merge("bold" => true),
                stored_box.merge("italic" => true), stored_box.merge("underline" => true),
                stored_box.merge("direction" => 2), stored_box.merge("color" => 1),
                stored_box.reject { |key, _| key == "oy" }]
    controls.each do |box|
      connector.label_boxes = { lmb: box }
      text = Nokogiri::XML(renderer.text_for(connector, [[100, 50], [200, 50]])).at_xpath("//text")

      expect([text["x"].to_f, text["y"].to_f]).to eq([150, 50]), box.inspect
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Label::MidpointLabel, "external connectors" do
  include_context "stored midpoint stereotype"

  it "preserves midpoint placement for non-model connectors" do
    external = Struct.new(:relationship_ref, :label_boxes).new(relationship.id, { lmb: stored_box })
    text = Nokogiri::XML(renderer.text_for(external, [[100, 50], [200, 50]])).at_xpath("//text")

    expect([text["x"].to_f, text["y"].to_f]).to eq([150, 50])
  end
end

RSpec.describe Ea::Svg::EaEmitter::Label::MidpointLabel, "unmeasured fonts and glyphs" do
  include_context "stored midpoint stereotype"

  it "preserves unmeasured fonts and glyphs" do
    renderers = [["Carlito", 7, "pt"], ["Cambria", 8, "pt"], ["Cambria", 7, "px"]]
    renderers.each do |family, size, unit|
      unmeasured = described_class.new(canvas: nil, model_index: { relationship.id => relationship },
                                       font_family: family, font_size: size, font_unit: unit)
      text = Nokogiri::XML(unmeasured.text_for(connector, [[100, 50], [200, 50]])).at_xpath("//text")

      expect([text["x"].to_f, text["y"].to_f]).to eq([150, 50])
    end
    connector.label_boxes = {}
    text = Nokogiri::XML(renderer.text_for(connector, [[100, 50], [200, 50]])).at_xpath("//text")
    expect([text["x"].to_f, text["y"].to_f]).to eq([150, 50])
    connector.label_boxes = { lmb: stored_box }
    relationship.stereotype = "☃"
    text = Nokogiri::XML(renderer.text_for(connector, [[100, 50], [200, 50]])).at_xpath("//text")
    expect([text["x"].to_f, text["y"].to_f]).to eq([150, 50])
  end
end
