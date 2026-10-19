# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  let(:document) do
    Ea::Sources::Qea::Adapter.from_path(File.expand_path("../../../fixtures/basic.qea", __dir__))
  end
  let(:diagram_name) { "Basic Object Diagram with Value Specification" }
  let(:diagram) { document.diagrams.find { |item| item.name == diagram_name } }
  let(:xml) do
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document
    ).render
    Nokogiri::XML(svg).remove_namespaces!
  end

  it "keeps a default center route and its caption on the native source row", :aggregate_failures do
    expect(xml.css("path").map { |node| node["d"] }).to include("M 168 66 L 272 66")
    caption = xml.css("text").find { |node| node.text == "Link A" }
    expect([caption["x"].to_f, caption["y"].to_f]).to eq([207, 63])
  end

  context "with aligned default centers" do
    let(:diagram_name) { "Starter Object Diagram" }

    it "preserves the native route and caption" do
      expect(xml.css("path").map { |node| node["d"] }).to include("M 125 65 L 250 65")
      caption = xml.css("text").find { |node| node.text == "Link A" }
      expect([caption["x"].to_f, caption["y"].to_f]).to eq([174, 62])
    end
  end
end
