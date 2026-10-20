# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA tagged-value display order" do
  include TrailingCompartmentFontHelpers

  it "seats simple.qea tags alphabetically as in its native SVG" do
    nodes = trailing_tag_public_nodes

    expect(nodes.map { |node| [node.text, node["x"].to_f, node["y"].to_f] })
      .to eq([["tags", 82, 89], ["isCollection = false", 40, 101],
              ["noPropertyType = false", 40, 113]])
  end
end

RSpec.describe "Tagged-value display preservation" do
  it "preserves source order and tag contents while displaying sorted rows" do
    tags = [Ea::Model::TaggedValue.new(key: "noPropertyType", value: "a & b"),
            Ea::Model::TaggedValue.new(key: "isCollection", value: "false")].freeze
    svg = Ea::Svg::EaEmitter::Element::TaggedValueRenderer.render(
      tags, bounds: Ea::Model::Bounds.new(x: 10, y: 20, width: 100, height: 100),
            first_y: 50, family: "Carlito", size: 9
    )

    expect(Nokogiri::XML("<svg>#{svg}</svg>").css("text").map(&:text))
      .to eq(["tags", "isCollection = false", "noPropertyType = a & b"])
    expect(tags.map { |tag| [tag.key, tag.value] })
      .to eq([["noPropertyType", "a & b"], ["isCollection", "false"]])
  end

  it "retains rows whose source key is missing" do
    svg = Ea::Svg::EaEmitter::Element::TaggedValueRenderer.render(
      [Ea::Model::TaggedValue.new(value: "false")],
      bounds: Ea::Model::Bounds.new(x: 10, y: 20, width: 100, height: 100),
      first_y: 50, family: "Carlito", size: 9
    )

    expect(Nokogiri::XML("<svg>#{svg}</svg>").css("text").map(&:text))
      .to eq(["tags", " = false"])
  end
end
