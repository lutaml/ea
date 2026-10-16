# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA leftward source property labels through the public adapter" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers

  let(:options) do
    { path: "500:-350;300:-350;", source: [500, 300, 200, 100], target: [100, 300, 200, 100],
      boxes: { "LLT" => [-7, 3], "LLB" => [-11, 2] },
      role: "lod-1MultiPoint", mult: "0..1", alignment: 1 }
  end

  it "uses the leftward property seat on a direct width-2 route" do
    result = render_qea_end_labels(**options, style: "Mode=1;LWidth=2;")
    role = result[:texts].find { |text| text[:text] == "+lod-1MultiPoint" }
    stereotype = result[:texts].find { |text| text[:text] == "«property»" }

    expect([role[:x], role[:y]]).to eq([result[:first][0] - 7 - 60 - 75, result[:first][1] + 3 - 7])
    expect([stereotype[:x], stereotype[:y]]).to eq([role[:x] + 14, role[:y] + 12])
    expect(result[:mult]).to eq([result[:first][0] - 11 - 16 - 3, result[:first][1] + 2 + 15])
    expect(result[:last]).to eq([result[:first][0] - 200, result[:first][1]])
  end

  it "preserves direct labels outside the measured property presentation" do
    [{ style: "Mode=1;LWidth=0;" }, { style: "Mode=1;LWidth=2;TREE=V;" },
     { style: "Mode=1;LWidth=2;", stereotype: "" }].each do |presentation|
      result = render_qea_end_labels(**options, **presentation)
      role = result[:texts].find { |text| text[:text] == "+lod-1MultiPoint" }

      expect([role[:x], role[:y]]).to eq([result[:first][0] - 7, result[:first][1] - 3])
      expect(result[:mult]).to eq([result[:first][0] - 30, result[:first][1] + 17])
    end
  end
end
