# frozen_string_literal: true

require "spec_helper"

module QeaSourceBottomPropertyHelpers
  include TestDatabaseHelper
  include QeaEndLabelHelpers

  BOXES = { "LRT" => [3, -26], "LRB" => [-3, 5] }.freeze

  def bottom_property_labels(offset: 0, stereotype: "property", style: "Mode=3;LWidth=2;")
    ends = { role: "lod0Geometry", mult: "0..1", stereotype: stereotype, style: style }
    tables = qea_end_label_tables("", BOXES, [604, 204, 160, 51], [185, 73, 276, 224], ends)
    tables[:diagram_links].first.geometry = bottom_property_geometry(offset)
    render_bottom_property(tables)
  end

  def bottom_property_geometry(offset)
    boxes = offset.zero? ? BOXES : BOXES.merge("LLT" => [offset, 0])
    qea_end_label_geometry(boxes).sub("SX=0;SY=0;EX=0;EY=0;EDGE=1;",
                                      "EDGE=2;SX=139;SY=-45;EX=34;EY=-1;")
  end

  def render_bottom_property(tables)
    document = Ea::Sources::Qea::Adapter.new(build_test_database(**tables), "bottom-property.qea").to_document
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false, content_anchor: false).render
    qea_end_label_result(Nokogiri::XML(svg).remove_namespaces!, "0..1")
  end
end

RSpec.describe "QEA zero-box source Property whose saved ray meets the bottom face" do
  include QeaSourceBottomPropertyHelpers

  it "uses the downward Property seat despite the leftward-upward clipped ray" do
    result = bottom_property_labels
    role, stereo = result[:texts].select { |text| ["+lod0Geometry", "«property»"].include?(text[:text]) }

    expect([role[:x], role[:y]]).to eq([result[:first][0] - 65 - 67, result[:first][1] + 15])
    expect([stereo[:x], stereo[:y]]).to eq([role[:x], role[:y] + 12])
    expect(result[:last][0]).to be < result[:first][0]
    expect(result[:last][1]).to be < result[:first][1]
  end

  it "seats moved source Property boxes at the downward corner" do
    result = bottom_property_labels(offset: 9)
    role = result[:texts].find { |text| text[:text] == "+lod0Geometry" }

    expect([role[:x], role[:y]]).to eq([result[:first][0] + 9 - 65 - 67, result[:first][1] + 15])
  end

  it "preserves plain roles" do
    result = bottom_property_labels(stereotype: "")
    role = result[:texts].find { |text| text[:text] == "+lod0Geometry" }

    expect([role[:x], role[:y]]).to eq(result[:first])
  end
end
