# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Moved plain source labels on saved vertical stairs" do
  include LabelSourceStairHelpers

  it "matches independently joined left and right native branches" do
    source_stair_records.each do |record|
      positions = source_stair_positions(source_stair_connector(record), record)

      expect(positions["+#{record[:role]}"]).to eq(record[:expected][0])
      expect(positions["0..*"]).to eq(record[:expected][1])
    end
  end

  it "follows a translated saved route" do
    record = source_stair_records.first
    connector = source_stair_connector(record)
    connector.waypoints.each do |waypoint|
      waypoint.position.x += 47
      waypoint.position.y -= 83
    end
    positions = source_stair_positions(connector, record)

    expect(positions["+#{record[:role]}"]).to eq([221, 283])
    expect(positions["0..*"]).to eq([551, 235])
  end
end

RSpec.describe "Source stair fallback controls" do
  include LabelSourceStairHelpers

  it "preserves unsupported routes" do
    record = source_stair_records.first
    mutations = [
      ->(c) { c.style[:mode] = "2" },
      ->(c) { c.style[:lwidth] = "2" },
      ->(c) { c.style[:tree] = "LV" },
      ->(c) { c.waypoints[2].position.y += 1 },
      ->(c) { c.waypoints.pop },
      ->(c) { c.waypoints[1].position.y = 300 }
    ]
    mutations.each_with_index do |mutate, index|
      connector = source_stair_connector(record)
      mutate.call(connector)
      positions = source_stair_positions(connector, record)

      expect(positions["+#{record[:role]}"]).to eq(index == 5 ? [174, 342] : [311, 272])
      expect(positions["0..*"]).to eq(index == 5 ? [504, 294] : [509, 315])
    end
  end
end

RSpec.describe "Source stair presentation and ownership controls" do
  include LabelSourceStairHelpers

  it "preserves unsupported boxes and presentations" do
    record = source_stair_records.first
    mutations = [
      ->(c) { c.label_boxes[:llt]["cy"] = 35 },
      ->(c) { c.label_boxes[:llb]["cy"] = 16 },
      ->(c) { c.label_boxes[:llt]["alignment"] = 0 },
      ->(c) { c.label_boxes[:llt]["rotation"] = 90 },
      ->(c) { c.label_boxes[:llt]["ox"] = c.label_boxes[:llt]["oy"] = 0 },
      ->(c) { c.label_boxes.delete(:llb) },
      ->(c) { c.source_stereotype = "property" }
    ]
    mutations.each do |mutate|
      connector = source_stair_connector(record)
      mutate.call(connector)
      baseline = source_stair_connector(record)
      mutate.call(baseline)
      baseline.style[:mode] = "2"

      expect(source_stair_positions(connector, record)).to eq(source_stair_positions(baseline, record))
    end
  end
end

RSpec.describe "Source stair font and endpoint controls" do
  include LabelSourceStairHelpers

  it "preserves custom font positions" do
    record = source_stair_records.first
    connector = source_stair_connector(record)
    expect(source_stair_positions(connector, record, family: "Carlito")["+#{record[:role]}"])
      .to eq([311, 272])
  end

  it "keeps the target endpoint and semantic ownership" do
    record = source_stair_records.first
    connector = source_stair_connector(record)
    connector.label_boxes = { lrt: connector.label_boxes[:llt], lrb: connector.label_boxes[:llb] }
    positions = source_stair_positions(connector, record, target: true)

    expect(positions.keys).to contain_exactly("+#{record[:role]}", "0..*")
    expect(positions["+#{record[:role]}"]).to eq([-2, 412])
  end
end
