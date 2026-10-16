# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA zero-box source Property leaving down on the LH tree route" do
  include QeaSourceTreePropertyHelpers

  it "uses the downward Property seat" do
    result = tree_property_labels
    role, stereo = result[:texts].select { |text| ["+lod0Geometry", "«property»"].include?(text[:text]) }

    expect([role[:x], role[:y]]).to eq([result[:first][0] - 65 - 67, result[:first][1] + 15])
    expect([stereo[:x], stereo[:y]]).to eq([role[:x], role[:y] + 12])
  end

  it "preserves moved source boxes and plain roles" do
    [{ offset: 9 }, { stereotype: "" }].each do |presentation|
      result = tree_property_labels(**presentation)
      role = result[:texts].find { |text| text[:text] == "+lod0Geometry" }

      expect([role[:x], role[:y]]).to eq([result[:first][0] + presentation.fetch(:offset, 0), result[:first][1]])
    end
  end

  it "keeps the rightward seat on the LV tree route" do
    result = tree_property_labels(tree: "LV")
    role = result[:texts].find { |text| text[:text] == "+lod0Geometry" }

    expect([role[:x], role[:y]]).to eq([result[:first][0] + 3, result[:first][1] - 7])
  end
end
