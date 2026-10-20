# frozen_string_literal: true

require "spec_helper"
require "ea"
require "nokogiri"
require "tempfile"

RSpec.describe Ea::Sources::Xmi::DiagramBuilder::UmldiEdges do
  let(:edges) { described_class.new(fixtures_path("issue135_route_style/4eb-role-seat-path.xmi")) }
  let(:diagram_id) { "EAID_4EB75007_B31D_4f2c_8855_7E9D3A3B17F4" }
  let(:connector_id) { "EAID_3677D889_F04B_4fb8_9651_5D1D972FBCD6" }

  it "returns absolute UMLDI label bounds by semantic end and label kind" do
    expect(edges.label_bounds_for(diagram_id, connector_id)).to eq(
      source_role: { x: 970, y: 245, width: 112, height: 25 },
      source_multiplicity: { x: 940, y: 328, width: 15, height: 13 }
    )
  end

  it "does not infer label bounds for ambiguous connector edges" do
    document = Nokogiri::XML(File.read(fixtures_path("issue135_route_style/4eb-role-seat-path.xmi")))
    diagram = document.xpath("//*[local-name()='Diagram']").first
    edge = diagram.xpath("./ownedElement").find do |node|
      node.attributes["type"]&.value.to_s.end_with?("UMLEdge")
    end
    diagram.add_child(edge.dup)

    Tempfile.create(["ambiguous-umldi-labels", ".xmi"]) do |file|
      file.write(document.to_xml)
      file.flush
      expect(described_class.new(file.path).label_bounds_for(diagram_id, connector_id)).to be_nil
    end
  end
end
