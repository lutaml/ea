# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Moved target labels on saved vertical stairs" do
  include LabelTargetBendHelpers

  it "matches three published role and multiplicity pairs from the first bend" do
    target_bend_records.each do |record|
      positions = target_bend_positions(target_bend_connector(record), record[:role])

      expect(positions["+#{record[:role]}"]).to eq(record[:expected][0])
      expect(positions["0..1"]).to eq(record[:expected][1])
    end
  end

  it "moves with the saved route without depending on diagram coordinates" do
    record = target_bend_records.first
    connector = target_bend_connector(record)
    connector.waypoints.each do |w|
      w.position.x -= 47
      w.position.y += 83
    end
    positions = target_bend_positions(connector, record[:role])

    expect(positions["+#{record[:role]}"]).to eq([863, 727])
    expect(positions["0..1"]).to eq([938, 727])
  end
end

RSpec.describe "Saved target bend route controls" do
  include LabelTargetBendHelpers

  it "preserves the endpoint fallback for other routes and diagonal stairs" do
    record = target_bend_records.first
    connectors = Array.new(3) { target_bend_connector(record) }
    connectors[0].style = { mode: "2", lwidth: "0", tree: "V" }
    connectors[1].waypoints[1].position.x += 1
    connectors[2].waypoints[2].position.y = 720

    connectors.each do |connector|
      positions = target_bend_positions(connector, record[:role])

      expect(positions["+#{record[:role]}"]).to eq([992, 743])
      expect(positions["0..1"]).to eq([980, 743])
    end
  end
end

RSpec.describe "Saved target bend presentation controls" do
  include LabelTargetBendHelpers

  it "preserves unmoved boxes and custom presentations" do
    record = target_bend_records.first
    connector = target_bend_connector(record)
    connector.label_boxes.each_value { |box| box["ox"] = box["oy"] = 0 }
    positions = target_bend_positions(connector, record[:role])

    expect(positions["+#{record[:role]}"]).to eq([876, 720])
    expect(positions["0..1"]).to eq([884, 713])
    connector = target_bend_connector(record)
    connector.label_boxes.each_value { |box| box["rotation"] = 90 }
    expect(target_bend_positions(connector, record[:role])["+#{record[:role]}"]).to eq([992, 743])
    expect(target_bend_positions(target_bend_connector(record), record[:role], family: "Carlito")["+#{record[:role]}"])
      .to eq([992, 743])
  end
end

RSpec.describe "Saved target bend semantic endpoint controls" do
  include LabelTargetBendHelpers

  it "does not copy semantic source roles into the empty target of the reversed trio" do
    %w[lod1MultiSolid lod2MultiSolid lod3MultiSolid].each do |role|
      connector = target_bend_connector(target_bend_records.first)
      positions = target_bend_positions(connector, role, source: true)

      expect(positions.keys).to eq(["+#{role}", "0..1"])
      expect(positions["+#{role}"]).to eq([873, 518])
    end
  end
end

RSpec.describe "Preserved source label of Plateau connector 724" do
  include LabelUpwardPropertyHelpers

  it "keeps the previously proved leftward Property role seat" do
    record = { role: "hollowSpaceInstallation", mult: "0..*", anchor: [305, 342],
               box: { "ox" => 206, "oy" => 50, "cx" => 126, "cy" => 31, "alignment" => 1 } }
    positions = upward_property_positions(record, heading: [-32, 0], type: "Aggregation",
                                                  style: { mode: "3", lwidth: "2" })

    expect(positions["+hollowSpaceInstallation"]).to eq([341, 385])
    expect(positions["«property»"]).to eq([372, 397])
  end
end
