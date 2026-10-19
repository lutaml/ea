# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA source Property roles on mode 2, LH tree and absent-box tree legs" do
  include LabelUpwardPropertyHelpers
  include LabelRoutePropertyHelpers

  it "seats each class at its directional Property seat" do
    route_property_records.each do |record|
      positions = route_property_positions(record)

      expect(positions["+#{record[:role]}"]).to eq(record[:expected]), record[:name]
      expect(positions["«property»"][1]).to eq(record[:expected][1] + 12), record[:name]
      expect(positions["«property»"][0]).to eq(record[:expected][0]), record[:name] if record[:box]["alignment"].zero?
    end
  end

  it "keeps the neighbouring route and unsupported presentations where they were" do
    route_property_records.each do |record|
      [record[:control], { family: "Carlito" }, { stereotype: nil },
       { box: record[:box].merge("rotation" => 90) }].each do |options|
        positions = route_property_positions(record, **options)

        expect(positions["+#{record[:role]}"]).to eq(route_property_stored(record)), "#{record[:name]} #{options.keys}"
      end
    end
  end
end
