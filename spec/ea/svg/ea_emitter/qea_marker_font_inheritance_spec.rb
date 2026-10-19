# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "QEA default-marker font inheritance" do
  include QeaCompartmentFontHelpers

  let(:document) { public_compartment_document }

  it "keeps diagram164 default classifiers on Cambria beside saved default-marker fonts" do
    diagram = document.diagrams.find { |entry| entry.id == "38170608-32B5-4a6f-A68D-A0D7C0C9D019" }
    placement = diagram.elements.find { |entry| entry.model_element_ref == "8E4996A7-C42C-4613-A0A4-9A6D855F0CF7" }
    resolver = Ea::Svg::EaEmitter::FontResolver.new(diagram, theme: diagram.theme)

    expect([placement.font_family, placement.font_size]).to eq([nil, nil])
    expect(resolver.family_for(placement)).to eq("Cambria")
    rows = compartment_texts(document, diagram.id).select do |node|
      node.text.start_with?("geometrySrcDescLod", "thematicSrcDesc:", "appearanceSrcDescLod",
                            "lodType:", "lod1HeightType:", "tranDataAcquisition:")
    end
    expect(rows.map { |node| node["y"].to_f }).to eq((701..857).step(12).to_a)
    expect(rows.map { |node| node["style"] }).to all(include("font-family:Cambria;", "font-size:7pt;"))
  end
end

RSpec.describe "Diagram fallback font candidates" do
  let(:plain) { Ea::Model::DiagramElement.new(id: "plain") }
  let(:marker) { Ea::Model::DiagramElement.new(id: "marker", font_family: "Yu Gothic UI") }
  let(:saved) { Ea::Model::DiagramElement.new(id: "saved", font_family: "Arial") }
  let(:diagram) { Ea::Model::Diagram.new(id: "fonts", elements: [plain, marker, saved]) }

  it "ignores use-default markers while retaining a saved real family" do
    resolver = Ea::Svg::EaEmitter::FontResolver.new(diagram)

    expect(resolver.family_for(plain)).to eq("Arial")
    expect(resolver.family_for(marker)).to eq("Arial")
    expect(resolver.family_for(saved)).to eq("Arial")
  end

  it "uses Cambria when every stored candidate is a default marker or empty" do
    diagram.elements = [plain, marker, Ea::Model::DiagramElement.new(id: "empty", font_family: "")]
    resolver = Ea::Svg::EaEmitter::FontResolver.new(diagram)

    expect(diagram.elements.map { |element| resolver.family_for(element) })
      .to eq(%w[Cambria Cambria Cambria])
  end

  it "keeps explicit markers on a themed default while nil placements use the element family" do
    resolver = Ea::Svg::EaEmitter::FontResolver.new(diagram, theme: Ea::Theme::Registry.lookup("119"))

    expect(resolver.family_for(marker)).to eq("Carlito")
    expect(resolver.family_for(plain)).to eq("Cambria")
    expect(resolver.family_for(saved)).to eq("Arial")
  end
end
