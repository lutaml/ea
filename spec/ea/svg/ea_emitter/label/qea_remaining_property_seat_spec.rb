# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA moved Property labels on horizontal arrivals and vertical stairs" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers
  include QeaRemainingPropertySeatHelpers

  let(:targets) do
    [
      { role: "lod3Network", path: "391:-496;", boxes: { "LRT" => [126, -56], "LRB" => [-25, 6] },
        style: "Mode=3;LWidth=2;TREE=LH;" },
      { role: "lod2Network", path: "310:-524;", boxes: { "LRT" => [49, 50], "LRB" => [-25, 1] },
        style: "Mode=3;LWidth=2;", geometry: "SX=-81;SY=-73;EX=-70;EY=-29;EDGE=3;" }
    ]
  end
  let(:stairs) do
    [
      { role: "ifcBuildingInstallationAttribute", path: "534:-400;420:-400;", target: [337, 450, 166, 70],
        boxes: { "LLT" => [-24, 46], "LLB" => [14, -10] }, width: 141, stereo_offset: 47 },
      { role: "ifcIntBuildingInstallationAttribute", path: "534:-400;915:-400;", target: [845, 450, 141, 70],
        boxes: { "LLT" => [481, 38], "LLB" => [62, -15] }, width: 153, stereo_offset: 53 }
    ]
  end

  it "seats moved target roles against the leftward corner" do
    targets.each do |record|
      result = remaining_target_property(record)
      role = result[:texts].find { |text| text[:text] == "+#{record[:role]}" }
      ox, oy = record[:boxes]["LRT"]

      expect([role[:x], role[:y]]).to eq([result[:last][0] + ox - 63 - 60, result[:last][1] + oy - 7])
      stereo = result[:texts].find { |text| text[:text] == "«property»" }
      expect([stereo[:x], stereo[:y]]).to eq([role[:x] + 8, role[:y] + 12])
    end
  end

  it "uses the moved stair baseline for source Property roles and multiplicities" do
    stairs.each do |record|
      result = remaining_stair_property(record)
      role = result[:texts].find { |text| text[:text] == "+#{record[:role]}" }
      ox, oy = record[:boxes]["LLT"]
      mx, my = record[:boxes]["LLB"]

      expect([role[:x], role[:y]]).to eq([result[:first][0] + ox - record[:width] - 60, result[:first][1] + oy + 18])
      stereo = result[:texts].find { |text| text[:text] == "«property»" }
      expect([stereo[:x], stereo[:y]]).to eq([role[:x] + record[:stereo_offset], role[:y] + 12])
      expect(result[:mult]).to eq([result[:first][0] + mx + 3, result[:first][1] + my + 18])
    end
  end

  it "preserves plain targets and unsupported target alignment" do
    targets.each do |record|
      [{ stereotype: "" }, { alignment: 0 }].each do |options|
        result = remaining_target_property(record, **options)
        role = result[:texts].find { |text| text[:text] == "+#{record[:role]}" }
        ox, oy = record[:boxes]["LRT"]

        expect([role[:x], role[:y]]).to eq([result[:last][0] + ox, result[:last][1] - oy])
      end
    end
  end

  it "preserves plain stair pairs and other routes" do
    stairs.each do |record|
      plain = remaining_stair_property(record, stereotype: "")
      role = plain[:texts].find { |text| text[:text] == "+#{record[:role]}" }
      ox, oy = record[:boxes]["LLT"]

      expect([role[:x], role[:y]]).to eq([plain[:first][0] + ox, plain[:first][1] - oy])
      other = remaining_stair_property(record, style: "Mode=3;LWidth=0;TREE=LV;")
      role = other[:texts].find { |text| text[:text] == "+#{record[:role]}" }
      expect([role[:x], role[:y]]).to eq([other[:first][0] + ox, other[:first][1] - oy])
    end
  end
end
