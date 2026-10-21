# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA straight origin rays" do # rubocop:disable Metrics/BlockLength
  include QeaCompartmentFontHelpers
  include QeaRoutingHelpers

  it "keeps the published stored Generalization ray on its header-divider row" do
    document = public_compartment_document
    diagram = document.diagrams.find { |entry| entry.connectors.any? { |connector| connector.id == "dc:190:1475" } }
    connector = diagram.connectors.find { |entry| entry.id == "dc:190:1475" }
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                    document: document, frame: true).render

    # Native (780,130)/(715,130), translated by the diagram frame.
    expect(Nokogiri::XML(svg).css("path").map { |node| node["d"] }).to include("M 808 162 L 743 162")
    expect(connector.style[:stored_origin_ray]).to be(true)
  end

  it "clips the published offset-free diagonal Association on both stroked outlines" do
    document = public_compartment_document
    diagram = document.diagrams.find { |entry| entry.connectors.any? { |connector| connector.id == "dc:117:642" } }
    connector = diagram.connectors.find { |entry| entry.id == "dc:117:642" }
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                    document: document, frame: true).render

    expect(connector.has_geometry_offsets).to be(false)
    # Native (702,215)/(590,214), translated by the diagram frame.
    expect(Nokogiri::XML(svg).css("path").map { |node| node["d"] }).to include("M 417 235 L 305 234")
    expect(connector.style[:stored_association_ray]).to be(true)
  end

  it "preserves authored and unsupported Generalization routes without producer certification" do
    input = { source: [781, 64, 202, 101], target: [327, 8, 387, 193],
              geometry: "SX=-81;SY=-17;EX=-4;EY=-26;EDGE=4;", path: nil, style: "Mode=3;LWidth=2;" }
    cases = [
      [{ style: "Mode=1;LWidth=2;" }, "M 488 162 L 423 162"],
      [{ style: "Mode=2;LWidth=2;" }, "M 488 127 L 423 123"],
      [{ style: "Mode=3;LWidth=0;" }, "M 489 162 L 422 162"],
      [{ style: "Mode=3;LWidth=1;" }, "M 489 162 L 422 162"],
      [{ style: "Mode=3;LWidth=2;TREE=V;" }, "M 488 127 L 423 123"],
      [{ style: "Mode=3;LWidth=2;Direct=1;" }, "M 423 162 L 488 162 M 423 162"],
      [{ style: "Mode=3;LWidth=2;Regenerated=1;" }, "M 488 162 L 423 162"],
      [{ path: "650:-200;" }, "M 489 168 L 358 232 L 214 233"],
      [{ connector_type: "Dependency" }, "M 489 127 L 422 123"]
    ]
    cases.each do |changes, path|
      result = render_qea_route(**input.merge(changes)) do |document|
        expect(document.diagrams.first.connectors.first.style[:stored_origin_ray]).to be_nil
      end
      expect(result[:paths].first).to eq(path), changes.inspect
    end
  end

  it "preserves offset-free Association styles outside the diagonal width-2 contract" do
    input = { source: [703, 177, 190, 80], target: [320, 20, 269, 387], geometry: "EDGE=4;",
              path: nil, style: "Mode=3;LWidth=2;", connector_type: "Association" }
    cases = [
      { style: "Mode=1;LWidth=2;" }, { style: "Mode=2;LWidth=2;" },
      { style: "Mode=3;LWidth=0;" }, { style: "Mode=3;LWidth=1;" },
      { style: "Mode=3;LWidth=2;TREE=V;" }, { style: "Mode=3;LWidth=2;Regenerated=1;" },
      { path: "650:-200;" }, { connector_type: "Dependency" }
    ]
    cases.each do |changes|
      result = render_qea_route(**input.merge(changes)) do |document|
        expect(document.diagrams.first.connectors.first.style[:stored_association_ray]).to be_nil
      end
      expect(result[:paths].first).to eq("M 418 235 L 304 234"), changes.inspect
    end
  end
end
