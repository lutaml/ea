# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Elements, "tag content height" do
  include BlankTagHelpers
  include TagContentWidthHelpers

  it "grows a stored h70 box to the native h85 for two shown tags (204F4ACC AcmeUmlClass)" do
    document, diagram = native_tag_document
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document).render
    box = Nokogiri::XML(svg).remove_namespaces!.css('rect[x="10"][y="10"]').first

    expect(diagram.elements.first.bounds.height).to eq(70)
    expect(box["height"]).to eq("85")
  end

  it "keeps a box whose stored height already holds the tags" do
    document = qea_tag_document({ "HighPrecision" => "false" })
    diagram = document.diagrams.first
    renderer = Ea::Svg::EaEmitter::Elements.new(diagram, model_index: document.index_by_id)
    renderer.render

    expect(renderer.drawn_bounds.fetch("class").height).to eq(diagram.elements.first.bounds.height)
  end

  it "does not grow the box for tags that are not shown" do
    document, diagram = native_tag_document
    diagram.elements.first.show_tagged_values = false
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document).render
    box = Nokogiri::XML(svg).remove_namespaces!.css('rect[x="10"][y="10"]').first

    expect(box["height"]).to eq("70")
  end
end
