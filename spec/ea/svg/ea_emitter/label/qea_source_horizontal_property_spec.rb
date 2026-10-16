# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA rightward horizontal-tree source Property labels" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers

  let(:options) do
    { path: "300:-350;500:-350;", boxes: { "LLT" => [-103, -15], "LLB" => [33, 6] },
      mult: "0..*", style: "Mode=3;LWidth=2;TREE=H;" }
  end

  it "mirrors the horizontal Property seat for both stored alignments and role widths" do
    [["tranDmAttribute", 77, 0], ["tranKeyValuePairAttribute", 121, 1]].each do |name, width, alignment|
      result = render_qea_end_labels(**options, role: name, alignment: alignment)
      role = result[:texts].find { |text| text[:text] == "+#{name}" }
      stereo = result[:texts].find { |text| text[:text] == "«property»" }

      expect([role[:x], role[:y]]).to eq([result[:first][0] - 103 + 60 + width, result[:first][1] - 15 - 7])
      expect([stereo[:x], stereo[:y]]).to eq([role[:x] + (alignment.zero? ? 0 : 37), role[:y] + 12])
      expect(result[:mult]).to eq([result[:first][0] + 33 + 3 + 14, result[:first][1] + 6 + 15])
      expect(result[:last]).to eq([result[:first][0] + 200, result[:first][1]])
    end
  end
end

RSpec.describe "QEA rightward source Property preservation" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers

  let(:options) do
    { path: "300:-350;500:-350;", boxes: { "LLT" => [-103, -15], "LLB" => [33, 6] },
      mult: "0..*", style: "Mode=3;LWidth=2;TREE=H;" }
  end

  it "preserves the plain seat outside the measured horizontal Property route" do
    [{ style: "Mode=1;LWidth=2;TREE=H;" }, { style: "Mode=3;LWidth=0;TREE=H;" },
     { style: "Mode=3;LWidth=2;TREE=V;" }, { stereotype: "" }].each do |presentation|
      result = render_qea_end_labels(**options, role: "tranDmAttribute", alignment: 1, **presentation)
      role = result[:texts].find { |text| text[:text] == "+tranDmAttribute" }

      expect([role[:x], role[:y]]).to eq([result[:first][0] - 103 + 3, result[:first][1] - 15 - 7])
      expect(result[:last]).to eq([result[:first][0] + 200, result[:first][1]])
    end
  end
end
