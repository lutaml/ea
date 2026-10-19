# frozen_string_literal: true

require "spec_helper"

module QeaSourceTopPropertyHelpers
  include TestDatabaseHelper
  include QeaEndLabelHelpers

  def top_property_labels(edge: 1, offset: 0, mult_offset: nil, stereotype: "property")
    ends = { role: "lod0Geometry", mult: "0..1", stereotype: stereotype, style: "Mode=3;LWidth=2;" }
    tables = qea_end_label_tables("", { "LRT" => [-11, -8], "LRB" => [-10, 8] },
                                  [647, 262, 118, 80], [489, 457, 276, 224], ends)
    tables[:diagram_links].first.geometry = top_property_geometry(edge, offset, mult_offset)
    render_top_property(tables)
  end

  def top_property_geometry(edge, offset, mult_offset)
    boxes = { "LRT" => [-11, -8], "LRB" => [-10, 8] }
    boxes["LLT"] = [offset, 0] unless offset.zero?
    unless mult_offset.nil?
      boxes["LLT"] = [0, 0] if offset.zero?
      boxes["LLB"] = [mult_offset, 0]
    end
    qea_end_label_geometry(boxes).sub("SX=0;SY=0;EX=0;EY=0;EDGE=1;",
                                      "EDGE=#{edge};SX=87;SY=112;EX=8;EY=-8;")
  end

  def render_top_property(tables)
    document = Ea::Sources::Qea::Adapter.new(build_test_database(**tables), "top-property.qea").to_document
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false).render
    qea_end_label_result(Nokogiri::XML(svg).remove_namespaces!, "0..1")
  end
end

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
