# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA tagged-value row spacing" do
  include TrailingCompartmentFontHelpers

  it "seats simple.qea diagram2 tags at the native caption and row baselines" do
    expect(trailing_tag_public_nodes.map { |node| node["y"].to_f }).to eq([89, 101, 113])
  end

  it "seats ArcGIS diagram4 tags on the same compact font cells as attributes" do
    path = File.expand_path("../../../../examples/qea/ArcGISWorkspace_template.qea", __dir__)
    document = Ea::Sources::Qea::Adapter.new(cached_qea_database(path), path).to_document
    diagram = document.diagrams.find { |entry| entry.id == "7C44AC09-27C1-47b3-9A85-88EC71C081FF" }
    nodes = trailing_public_text_nodes(document, diagram).select do |node|
      node.text == "tags" || node.text.include?(" = ")
    end

    expect(nodes.map { |node| node["y"].to_f }).to eq((275..467).step(12).to_a)
  end
end
