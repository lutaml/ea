# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe "QEA connector ghost labels" do
  let(:document) { Ea::Sources::Qea::Adapter.from_path("examples/qea/20251010_current_plateau_v5.1.qea") }
  let(:italic_names) do
    lambda do |guid|
      diagram = document.diagrams.find { |entry| entry.id.include?(guid) }
      svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                      document: document).render
      texts = Nokogiri::XML(svg).remove_namespaces!.xpath("//text")
      texts.select { |node| node["style"].to_s.include?("font-style:italic") }.map(&:text)
    end
  end

  it "omits names of classifiers that only appear on undrawn connectors" do
    expect(italic_names.call("38170608")).not_to include("FacilityIdAttribute", "FacilityTypeAttribute",
                                                         "FacilityAttribute", "DmAttribute")
  end

  it "keeps the italic parent name drawn in a class header" do
    expect(italic_names.call("8DAB169F")).to include("_CityObject")
  end
end
