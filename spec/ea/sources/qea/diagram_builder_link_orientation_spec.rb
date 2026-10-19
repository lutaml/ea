# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  let(:path) { File.expand_path("../../../../examples/qea/20251010_current_plateau_v5.1.qea", __dir__) }
  let(:database) { Ea::Qea::Services::DatabaseLoader.new(path).load }
  let(:diagram_row) { database.diagrams.find { |row| row.diagram_id == 32 } }

  it "keeps reversed stored corners in semantic relationship order", :aggregate_failures do
    diagram = described_class.new(database).build_one(diagram_row)
    { "8D4E3649" => [[501, 685], [460, 320], [350, 355]],
      "4B08B8F8" => [[460, 708], [460, 343], [350, 367]],
      "1A604A28" => [[460, 720], [460, 367], [350, 380]] }.each do |prefix, points|
      connector = diagram.connectors.find { |row| row.relationship_ref.start_with?(prefix) }
      expect(connector.waypoints.map { |wp| [wp.position.x, wp.position.y] })
        .to eq(points)
      expect([connector.target_anchor.x, connector.target_anchor.y]).to eq([225, 395])
    end
  end

  it "preserves the normal stored direction and its offsets" do
    diagram = described_class.new(database).build_one(diagram_row)
    connector = diagram.connectors.find { |row| row.relationship_ref.start_with?("04FE2A6F") }
    expect(connector.waypoints.map { |wp| [wp.position.x, wp.position.y] })
      .to eq([[350, 395], [460, 395], [460, 720]])
    expect([connector.source_anchor.x, connector.source_anchor.y]).to eq([225, 395])
    expect([connector.target_anchor.x, connector.target_anchor.y]).to eq([460, 760])
  end

  it "retains stored routes for missing, partial, unknown and ambiguous placement IDs" do
    link = database.diagram_links_for(32).find { |row| row.connectorid == 755 }
    styles = ["Mode=3;LWidth=0;SOID=11117DB7;EOID=2DD4FF8E;", "Mode=3;LWidth=0;", "Mode=3;LWidth=0;SOID=2DD4FF8E;",
              "Mode=3;LWidth=0;SOID=unknown;EOID=11117DB7;",
              "Mode=3;LWidth=0;SOID=11117DB7;EOID=11117DB7;"]
    styles.each do |style|
      link.style = style
      expect(reversed_route).to eq([[510, 320], [460, 320], [460, 530]]), style
    end
    link.style = "Mode=3;LWidth=0;SOID=2DD4FF8E;EOID=11117DB7;"
    database.diagram_objects_for(32).find { |row| row.ea_object_id == 185 }.objectstyle = "DUID=2DD4FF8E;"
    expect(reversed_route).to eq([[510, 320], [460, 320], [460, 530]])
  end

  it "preserves incomplete offsets and self references" do
    link = database.diagram_links_for(32).find { |row| row.connectorid == 755 }
    link.geometry = "SX=41;SY=75;EX=0;EDGE=2;"
    expect(reversed_route).to eq([[510, 320], [460, 320], [460, 530]])
    link.geometry = "SX=41;SY=75;EX=0;EY=0;EDGE=2;"
    connector = database.find_connector(755)
    connector.end_object_id = connector.start_object_id
    before = reversed_route
    link.style = "Mode=3;LWidth=0;"
    expect(reversed_route).to eq(before)
  end

  let(:reversed_route) do
    diagram = described_class.new(database).build_one(diagram_row)
    connector = diagram.connectors.find { |row| row.relationship_ref.start_with?("8D4E3649") }
    connector.waypoints.map { |wp| [wp.position.x, wp.position.y] }
  end
end
