# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../support/qea_source_top_property_helpers"

RSpec.describe "QEA zero-box source Property at a saved top dock" do
  include QeaSourceTopPropertyHelpers

  it "uses the upward Property seat despite the downward diagonal ray" do
    result = top_property_labels
    role, stereo = result[:texts].select { |text| ["+lod0Geometry", "«property»"].include?(text[:text]) }

    expect([role[:x], role[:y]]).to eq([result[:first][0] - 60 - 67, result[:first][1] - 6])
    expect([stereo[:x], stereo[:y]]).to eq([role[:x], role[:y] + 12])
    expect(result[:last][0]).to be < result[:first][0]
    expect(result[:last][1]).to be > result[:first][1]
  end

  it "seats multiplicity with the upward Property cluster" do
    result = top_property_labels
    role, stereo = result[:texts].select { |text| ["+lod0Geometry", "«property»"].include?(text[:text]) }

    expect(result[:mult]).to eq([result[:first][0] + 3, result[:first][1] - 6])
    expect([stereo[:x], stereo[:y]]).to eq([role[:x], role[:y] + 12])
  end
end

RSpec.describe "QEA source Property seat preservation" do
  include QeaSourceTopPropertyHelpers

  it "preserves uncertified docks, moved source boxes and plain roles" do
    [{ edge: 2 }, { offset: 9 }, { stereotype: "" }].each do |presentation|
      result = top_property_labels(**presentation)
      role = result[:texts].find { |text| text[:text] == "+lod0Geometry" }
      stereo = result[:texts].find { |text| text[:text] == "«property»" }

      expect([role[:x], role[:y]]).to eq([result[:first][0] + presentation.fetch(:offset, 0), result[:first][1]])
      mult_position = presentation.fetch(:offset, 0).zero? ? [12, 15] : [presentation[:offset], 0]
      expect(result[:mult]).to eq([result[:first][0] + mult_position[0], result[:first][1] + mult_position[1]])
      expect([stereo[:x], stereo[:y]]).to eq([role[:x], role[:y] + 12]) if stereo
    end
  end

  it "preserves an explicitly moved multiplicity box" do
    result = top_property_labels(mult_offset: 9)
    role, stereo = result[:texts].select { |text| ["+lod0Geometry", "«property»"].include?(text[:text]) }

    expect([role[:x], role[:y]]).to eq([result[:first][0] - 60 - 67, result[:first][1] - 6])
    expect([stereo[:x], stereo[:y]]).to eq([role[:x], role[:y] + 12])
    expect(result[:mult]).to eq([result[:first][0] + 9, result[:first][1]])
  end
end
