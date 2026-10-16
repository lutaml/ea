# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA enumeration literal captions" do
  include QeaContentHelpers

  let(:document) { Ea::Sources::Qea::Adapter.from_path("examples/qea/test.qea") }
  let(:nodes) { qea_text_nodes(document, "B58D1A53") }
  let(:enumeration) { document.classifiers.find { |entry| entry.name == "Enumeration" } }

  it "captions literals even when none has a stored code value" do
    expect(enumeration).to be_a(Ea::Model::Enumeration)
    expect(enumeration.literals.map(&:name)).to eq(%w[val1 val2])
    expect(enumeration.literals.map(&:value)).to eq(%w[val1 val2])
    expect(nodes.map(&:text)).to include("literals", "val1", "val2")
  end

  it "places the italic caption one row above the first literal" do
    caption = nodes.find { |node| node.text == "literals" }
    first = nodes.find { |node| node.text == "val1" }
    second = nodes.find { |node| node.text == "val2" }

    expect(caption).not_to be_nil
    expect(caption["style"]).to include("font-style:italic")
    expect(first["y"].to_f - caption["y"].to_f).to eq(second["y"].to_f - first["y"].to_f)
    expect(first["y"].to_f).to be > caption["y"].to_f
  end
end

RSpec.describe "Enumeration compartment rows" do
  include EnumCaptionHelpers
  let(:literals) { %w[Red Green Blue].map { |name| Ea::Model::EnumerationLiteral.new(name: name) } }
  let(:renderer) { enum_caption_renderer(literals) }
  let(:nodes) { Nokogiri::XML("<svg>#{renderer.render}</svg>").xpath("//text") }

  it "reserves a row for the caption when growing a box without code values" do
    last = nodes.find { |node| node.text == "Blue" }
    drawn = renderer.drawn_bounds.fetch("enum")

    expect(nodes.map(&:text)).to include("literals")
    expect(drawn.height).to eq(last["y"].to_f + 8)
    expect(renderer.diagram.elements.first.bounds.height).to eq(50)
  end

  context "with no literals" do
    let(:literals) { [] }

    it "omits the literal compartment and its caption row" do
      expect(nodes.map(&:text)).to eq(["«enumeration»", "Color"])
      expect(renderer.drawn_bounds.fetch("enum").height).to eq(50)
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Compartment::EnumLiterals do
  it "preserves bare names, equal-value names and distinct code values" do
    { nil => "Blue", "" => "Blue", "Blue" => "Blue", "B" => "Blue = B" }.each do |value, expected|
      literal = Ea::Model::EnumerationLiteral.new(name: "Blue", value: value)

      expect(described_class.literal_display(literal)).to eq(expected)
    end
  end
end
