# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Bent routes with omitted source label boxes" do
  include LabelHeadingHelpers
  include LabelBentSourceHelpers

  it "seats the published exterior and interior clusters on their source exit face" do
    { "exterior" => [411, "1"], "interior" => [399, "0..*"] }.each do |role, (y, mult)|
      record = bent_source_record(role)
      positions = heading_positions(bent_source_connector(record), heading_bounds_for(record), role: role, mult: mult)

      expect(positions["+#{role}"]).to eq([435, y])
      expect(positions["«property»"]).to eq([435, y + 12])
      expect(positions[mult]).to eq([435, y + 22])
    end
  end
end

RSpec.describe "Ambiguous source docks on bent routes" do
  include LabelHeadingHelpers
  include LabelBentSourceHelpers

  it "keeps unresolved, inward and corner docks on their diagonal heading" do
    record = bent_source_record("exterior")
    connector = bent_source_connector(record)
    bounds = heading_bounds_for(record)
    unresolved = heading_positions(connector, bounds.slice("source"), role: "exterior")
    connector.waypoints[1].position.x = 400
    inward = heading_positions(connector, bounds, role: "exterior")
    connector.waypoints.first.position = heading_point([431, 370])
    corner = heading_positions(connector, bounds, role: "exterior")

    expect(unresolved["+exterior"]).to eq([432, 418])
    expect(inward["+exterior"]).to eq([432, 418])
    expect(corner["+exterior"]).to eq([431, 370])
  end
end

RSpec.describe "Explicit source boxes on bent routes" do
  include LabelHeadingHelpers
  include LabelBentSourceHelpers

  it "preserves explicit zero and moved source boxes on the same manual bend" do
    record = bent_source_record("exterior")
    [{ "ox" => 0, "oy" => 0, "alignment" => 0 },
     { "ox" => 24, "oy" => -21, "alignment" => 1 }].each do |box|
      connector = bent_source_connector(record)
      connector.label_boxes[:llt] = box
      connector.label_boxes[:llb] = { "ox" => 10, "oy" => -2, "alignment" => 1 }
      positions = heading_positions(connector, heading_bounds_for(record), role: "exterior", mult: "1")

      expect(positions["+exterior"]).to eq([432 + box["ox"], 418 - box["oy"]])
      expect(positions["1"]).to eq([442, 420])
    end
  end
end
