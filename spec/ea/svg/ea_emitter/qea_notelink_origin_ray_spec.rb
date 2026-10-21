# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA NoteLink origin rays" do # rubocop:disable Metrics/BlockLength
  include QeaCompartmentFontHelpers
  include QeaRoutingHelpers

  { "dc:28:108" => "M 116 421 L 113 459 M 116 421", "dc:70:467" => "M 119 421 L 121 459 M 119 421" }.each do |id, path|
    it "clips #{id} using mathematical saved Y offsets" do
      document = public_compartment_document
      diagram = document.diagrams.find { |entry| entry.connectors.any? { |connector| connector.id == id } }
      svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                      document: document, frame: true).render
      expect(Nokogiri::XML(svg).css("path").map { |node| node["d"] }).to include(path), id
    end
  end

  it "preserves unsupported and authored NoteLink origins" do
    input = { source: [280, 440, 280, 70], target: [280, 320, 130, 80],
              geometry: "SX=-72;SY=28;EX=8;EY=-22;EDGE=1;", path: nil,
              style: "Mode=3;LWidth=2;", connector_type: "NoteLink" }
    cases = [{ style: "Mode=1;LWidth=2;" }, { style: "Mode=2;LWidth=2;" },
             { style: "Mode=3;LWidth=0;" }, { style: "Mode=3;LWidth=1;" },
             { style: "Mode=3;LWidth=2;TREE=V;" },
             { style: "Mode=3;LWidth=2;Direct=1;" }, { style: "Mode=3;LWidth=2;Regenerated=1;" },
             { path: "350:-420;" },
             { geometry: "SX=-72;SY=28;EDGE=1;" },
             { geometry: "SX=-72;SY=28;EX=8;EY=-22;EDGE=2;" },
             { geometry: "SX=-72;SY=200;EX=8;EY=-22;EDGE=1;" },
             { connector_type: "Dependency" }]
    cases.each do |changes|
      render_qea_route(**input.merge(changes)) do |document|
        connector = document.diagrams.first.connectors.first
        geometry = input.merge(changes)[:geometry]
        sy = geometry[/SY=(-?\d+)/, 1].to_i
        ey = geometry[/EY=(-?\d+)/, 1].to_i
        expect([connector.source_anchor.y, connector.target_anchor.y]).to eq([475 + sy, 360 + ey]), changes.inspect
      end
    end
  end
end
