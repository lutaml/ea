# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA source Property roles on the OS route" do
  include LabelUpwardPropertyHelpers
  include LabelOrthogonalPropertyHelpers

  it "seats up, left and down roles at the directional corner seats" do
    orthogonal_property_records.each do |record|
      positions = orthogonal_property_positions(record)

      expect(positions["+#{record[:role]}"]).to eq(record[:expected]), record[:direction].to_s
      expect(positions["«property»"]).to eq([record[:expected][0], record[:expected][1] + 12])
    end
  end

  it "keeps other routes, presentations and moved boxes at their stored offsets" do
    orthogonal_property_records.product(orthogonal_property_controls).each do |record, options|
      stored = [record[:anchor][0] + record[:box]["ox"], record[:anchor][1] - record[:box]["oy"]]

      expect(orthogonal_property_positions(record, options)["+#{record[:role]}"])
        .to eq(stored), "#{record[:direction]} #{options.keys}"
    end
  end
end
