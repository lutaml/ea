# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "Adapter-built UMLDI source roles on 348EE46E" do
  let(:path) { fixtures_path("issue135_route_style/348e-lod0-roles.xmi") }
  let(:document) { Ea::Sources::Xmi::Adapter.from_path(path) }
  let(:diagram) { document.diagrams.first }
  let(:texts) do
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document, frame: true).render
    Nokogiri::XML(svg).xpath("//*[local-name()='text']").map { |node| [node.text, [node["x"].to_f, node["y"].to_f]] }
  end

  describe "declared property roles" do
    it "seats lod0RoofEdge and lod0FootPrint at their saved UMLDI bounds" do
      expect(texts.to_h.slice("+lod0RoofEdge", "+lod0FootPrint"))
        .to eq("+lod0RoofEdge" => [487.0, 307.0], "+lod0FootPrint" => [543.0, 225.0])
    end

    it "keeps the held-out roles at their native seats" do
      expect(texts.to_h.slice("+bldgKeyValuePairAttribute", "+largeCustomerFacilityAttribute"))
        .to eq("+bldgKeyValuePairAttribute" => [442.0, 388.0],
               "+largeCustomerFacilityAttribute" => [336.0, 515.0])
    end
  end

  describe "ALN=1 stereotypes" do
    it "centres each stereotype under its role bounds" do
      expect(texts.select { |text, _| text == "«property»" }.map(&:last))
        .to include([479.0, 400.0], [543.0, 237.0], [487.0, 319.0])
    end
  end
end
