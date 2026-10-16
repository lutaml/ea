# frozen_string_literal: true

require "spec_helper"

module QeaSourceBottomDirectionHelpers
  include TestDatabaseHelper
  include QeaEndLabelHelpers

  def bottom_property_labels(offset: [0, 0], alignment: 1, stereotype: "property", rotation: 0)
    boxes = { "LLT" => offset, "LLB" => [0, 0], "LRT" => [3, -26], "LRB" => [-3, 5] }
    ends = { role: "lod0Geometry", mult: "0..1", stereotype: stereotype, alignment: alignment }
    tables = qea_end_label_tables("", boxes, [604, 904, 160, 51], [185, 773, 276, 224], ends)
    tables[:diagram_links].first.geometry = bottom_direction_geometry(boxes, alignment, rotation)
    render_bottom_direction(tables)
  end

  def bottom_direction_geometry(boxes, alignment, rotation)
    qea_end_label_geometry(boxes, alignment: alignment)
      .sub("SX=0;SY=0;EX=0;EY=0;EDGE=1;", "EDGE=2;SX=139;SY=-45;EX=34;EY=-1;")
      .sub("ROT=0", "ROT=#{rotation}")
  end

  def render_bottom_direction(tables)
    database = build_test_database(**tables)
    document = Ea::Sources::Qea::Adapter.new(database, "bottom-property.qea").to_document
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false).render
    qea_end_label_result(Nokogiri::XML(svg).remove_namespaces!, "0..1")
  end
end

RSpec.describe "QEA source Property direction at an external saved bottom dock" do
  include QeaSourceBottomDirectionHelpers

  it "keeps the bottom seat independently of stored source label offsets" do
    [[0, 0], [11, -4]].each do |offset|
      result = bottom_property_labels(offset: offset)
      role = result[:texts].find { |text| text[:text] == "+lod0Geometry" }

      expect([role[:x], role[:y]]).to eq([result[:first][0] + offset[0] - 65 - 67,
                                          result[:first][1] + offset[1] + 15])
      expect(result[:mult]).to eq([result[:first][0] + 8, result[:first][1] + 15])
      expect(result[:last][0]).to be < result[:first][0]
      expect(result[:last][1]).to be < result[:first][1]
    end
  end

  it "preserves a rotated zero-offset source label box" do
    result = bottom_property_labels(alignment: 0, rotation: 15)
    role = result[:texts].find { |text| text[:text] == "+lod0Geometry" }

    expect([role[:x], role[:y]]).to eq(result[:first])
  end

  it "preserves moved alignment-zero labels and plain role offsets" do
    [{ offset: [11, -4], alignment: 0 }, { offset: [11, -4], stereotype: "" }].each do |presentation|
      result = bottom_property_labels(**presentation)
      role = result[:texts].find { |text| text[:text] == "+lod0Geometry" }

      expect([role[:x], role[:y]]).to eq([result[:first][0] + 11, result[:first][1] + 4])
    end
  end
end
