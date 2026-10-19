# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.shared_context "saved package and object captions" do
  let(:relationship) do
    Ea::Model::Dependency.new(id: "caption", client_id: "a", supplier_id: "b", stereotype: "import")
  end
  let(:connector) { Ea::Model::DiagramConnector.new(id: "caption", relationship_ref: relationship.id) }
  let(:renderer) do
    described_class.new(canvas: nil, model_index: { relationship.id => relationship },
                        font_family: "Cambria", font_size: 7, font_unit: "pt")
  end
  let(:box) do
    Ea::Sources::Qea::DiagramBuilder.new(nil).parse_label_boxes(
      "$LMB=CX=54:CY=18:OX=0:OY=0:HDN=0:BLD=0:ITA=0:UND=0:CLR=-1:ALN=0:DIR=0:ROT=0;"
    ).fetch(:lmb)
  end
end

RSpec.describe Ea::Svg::EaEmitter::Label::MidpointLabel do
  include_context "saved package and object captions"

  it "uses saved alignment-zero import seats and offsets in plateau diagram 123" do
    # QEA/XMI connectors 8F6BFB6E, C928AE98 and 604544F9; native positions
    # (137,140), (285,133), (213,230), before canvas translation (-210,-50).
    [
      [[[401, 151], [333, 229]], [-1, -13], [347, 190]],
      [[[483, 151], [545, 219]], [0, -15], [495, 183]],
      [[[509, 266], [375, 268]], [0, 0], [423, 280]]
    ].each do |points, offsets, expected|
      connector.label_boxes = { lmb: box.merge("ox" => offsets[0], "oy" => offsets[1]) }
      text = Nokogiri::XML(renderer.text_for(connector, points)).at_xpath("//text")

      expect([text["x"].to_f, text["y"].to_f]).to eq(expected)
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Label::MidpointLabel do
  include_context "saved package and object captions"

  it "centers saved object names on their horizontal bent leg" do
    # Basic diagram 8: connectors 0273F609 (Link A), 97A0AE9F (Link B).
    relationship.stereotype = nil
    [
      ["Link A", [[182, 180], [182, 135], [329, 135]], 0, -2, [246, 130]],
      ["Link B", [[178, 255], [178, 302], [329, 302]], 1, -4, [244, 295]]
    ].each do |name, points, alignment, offset_y, expected|
      relationship.name = name
      connector.label_boxes = { lmt: box.merge("cx" => 27, "cy" => 13, "ox" => 4,
                                               "oy" => offset_y, "alignment" => alignment) }
      text = Nokogiri::XML(renderer.text_for(connector, points)).at_xpath("//text")

      expect([text["x"].to_f, text["y"].to_f, text.text]).to eq([*expected, name])
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Label::MidpointLabel do
  include_context "saved package and object captions"

  it "preserves unsupported alignment-zero name seats and styled import boxes" do
    relationship.stereotype = nil
    relationship.name = "Link A"
    connector.label_boxes = { lmt: box }
    text = Nokogiri::XML(renderer.text_for(connector, [[100, 50], [200, 50]])).at_xpath("//text")
    expect([text["x"].to_f, text["y"].to_f]).to eq([150, 50])

    relationship.stereotype = "import"
    [box.merge("rotation" => 30), box.merge("bold" => true), box.merge("hidden" => true)].each do |unsupported|
      connector.label_boxes = { lmb: unsupported }
      text = Nokogiri::XML(renderer.text_for(connector, [[100, 50], [200, 50]])).at_xpath("//text")
      expect([text["x"].to_f, text["y"].to_f]).to eq([150, 50])
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Label::MidpointLabel do
  include_context "saved package and object captions"

  it "preserves alignment-zero fallback for unmeasured fonts and glyphs" do
    connector.label_boxes = { lmb: box }
    [["Carlito", 7, "pt"], ["Cambria", 8, "pt"], ["Cambria", 7, "px"]].each do |family, size, unit|
      unmeasured = described_class.new(canvas: nil, model_index: { relationship.id => relationship },
                                       font_family: family, font_size: size, font_unit: unit)
      text = Nokogiri::XML(unmeasured.text_for(connector, [[100, 50], [200, 50]])).at_xpath("//text")
      expect([text["x"].to_f, text["y"].to_f]).to eq([150, 50])
    end
    relationship.stereotype = "☃"
    text = Nokogiri::XML(renderer.text_for(connector, [[100, 50], [200, 50]])).at_xpath("//text")
    expect([text["x"].to_f, text["y"].to_f]).to eq([150, 50])
  end
end
