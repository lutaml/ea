# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "Source title font selection" do
  include QeaCompartmentFontHelpers

  it "uses the saved marker font beside default Cambria classifiers in plateau diagram164" do
    rows = compartment_texts(public_compartment_document, "38170608-32B5-4a6f-A68D-A0D7C0C9D019")
    %w[uro::KeyValuePairAttribute wtr::WaterBody].each do |name|
      title = rows.find { |row| row.text == name }
      expect(title["style"]).to include("font-family:Carlito;", "font-size:9pt;")
    end
    title = rows.find { |row| row.text == "uro::RiverFloodingRiskAttribute" }
    expect(title["style"]).to include("font-family:Cambria;", "font-style:normal;")
  end

  it "renders basic Domain Model hand drawn titles with the native italic family" do
    document = Ea::Sources::Qea::Adapter.from_path("examples/qea/basic.qea")
    rows = compartment_texts(document, "E325B9D8-E955-4aed-8125-63167BD40320")
    ["Concept A", "Concept B", "Concept C"].each do |name|
      title = rows.find { |row| row.text == name }
      expect(title["style"]).to include("font-family:Source Sans Pro;", "font-style:italic;", "font-weight:700;")
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::FontResolver, "hand drawn font precedence" do
  let(:plain) { Ea::Model::DiagramElement.new(id: "plain") }
  let(:explicit) do
    Ea::Model::DiagramElement.new(id: "explicit", font_family: "Arial", style: { italic: "0" })
  end
  let(:diagram) { Ea::Model::Diagram.new(id: "drawing", hand_draw: true, elements: [plain, explicit]) }
  let(:resolver) { described_class.new(diagram, theme: Ea::Theme::Registry.lookup("119")) }

  it "preserves explicit family and normal style before drawing defaults" do
    expect([resolver.family_for(plain), resolver.style_for(plain)]).to eq(["Source Sans Pro", "italic"])
    expect([resolver.family_for(explicit), resolver.style_for(explicit)]).to eq(%w[Arial normal])
  end

  it "keeps header roles and explicitly normal titles while styling hand drawn names" do
    expect(resolver.header_style_for(:bold, plain)).to eq(:bold_italic)
    expect(resolver.header_style_for(:bold, explicit)).to eq(:bold)
    expect(resolver.header_style_for(:normal, plain)).to eq(:normal)
    expect(resolver.header_style_for(:italic_tight, plain)).to eq(:italic_tight)
    diagram.hand_draw = false
    plain.font_italic = true
    expect(resolver.header_style_for(:bold, plain)).to eq(:bold)
  end

  it "preserves ordinary themed defaults when hand drawing is disabled" do
    diagram.hand_draw = false
    expect([resolver.family_for(plain), resolver.style_for(plain)]).to eq(%w[Cambria normal])
  end
end
