# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA target-owned aggregation navigability arrow" do
  include QeaMarkerHelpers

  [
    ["Aggregation", 1, "#FFFFFF"],
    ["Aggregation", 2, "#000000"],
    ["Composition", 2, "#000000"]
  ].each do |type, flag, fill|
    it "draws only the #{fill} target diamond for a #{type} flagged #{flag} directed Source -> Destination" do
      geometry = diamond_geometry(connector_type: type, destisaggregate: flag,
                                  destisnavigable: 0, direction: "Source -> Destination")

      expect(geometry[:tip]).to eq(geometry[:finish])
      expect(geometry[:keys]).to eq([fill])
      expect(geometry[:arrows]).to eq(0)
    end
  end

  # Arrow positions for these directions are asserted in
  # marker/registry_spec.rb; this only guards that the rule above stays
  # limited to Source -> Destination.
  ["Destination -> Source", "Bi-Directional"].each do |direction|
    it "keeps the #{direction} arrow beside the target diamond" do
      geometry = diamond_geometry(connector_type: "Aggregation", destisaggregate: 1,
                                  direction: direction)

      expect(geometry[:tip]).to eq(geometry[:finish])
      expect(geometry[:arrows]).to eq(1)
    end
  end
end
