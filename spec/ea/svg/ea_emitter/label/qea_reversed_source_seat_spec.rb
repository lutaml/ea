# frozen_string_literal: true

require "spec_helper"

# Plateau diagram 5038EEE3: connectors 207 (TREE=LV) and 212 (TREE=V) store
# SOID/EOID in the reverse of Start/End. EA seats their source labels like a
# source leaving left (role right edge 60px out and 7px above the anchor,
# multiplicity ending 3px short of it and 15px below), whichever way the
# route leaves the Start box.
# rubocop:disable Metrics/BlockLength
RSpec.describe "QEA source labels of reversed-end vertical trees" do
  include QeaEndLabelHelpers

  let(:beside_geometry) do
    "SX=86;SY=-4;EX=0;EY=0;EDGE=3;$LRT=CX=19:CY=16:OX=0:OY=0:HDN=0:BLD=0:ITA=0:UND=0:CLR=-1:ALN=1:DIR=0:ROT=0;"
  end

  # rubocop:disable Metrics/AbcSize
  def reversed_labels(tree:, soid: "PCPC", eoid: "MSMS", geometry: nil, path: nil)
    style = "Mode=3;EOID=#{eoid};SOID=#{soid};Color=-1;LWidth=0;TREE=#{tree};"
    tables = qea_end_label_tables(path, { "LRT" => [-38, -7], "LRB" => [-42, -7] },
                                  [610, 720, 153, 80], [630, 260, 268, 258],
                                  role: "lod1MultiSurface", mult: "0..1", alignment: 1, style: style)
    tables[:diagram_objects].zip(%w[MSMS PCPC]) { |row, duid| row.objectstyle = "DUID=#{duid};" }
    tables[:diagram_links].first.geometry = geometry if geometry
    document = Ea::Sources::Qea::Adapter.new(build_test_database(**tables), "reversed.qea").to_document
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false).render
    qea_end_label_result(Nokogiri::XML(svg).remove_namespaces!, "0..1")
  end
  # rubocop:enable Metrics/AbcSize

  # Role and multiplicity positions relative to the connector's first point.
  def seat(result)
    role = result[:texts].find { |text| text[:text] == "+lod1MultiSurface" }
    anchor_x, anchor_y = result[:first]
    mult_x, mult_y = result[:mult]
    { role: [role[:x] - anchor_x, role[:y] - anchor_y], mult: [mult_x - anchor_x, mult_y - anchor_y] }
  end

  let(:role_width) { Ea::Fonts::Metrics.text_length("+lod1MultiSurface", 7, family: "Cambria") }

  it "seats the source cluster left of the anchor on a reversed LV tree" do
    expect(seat(reversed_labels(tree: "LV"))).to eq(role: [-60 - role_width, -7], mult: [-19, 15])
  end

  it "seats a source leg that starts beside its box the same way (connector 212)" do
    result = reversed_labels(tree: "V", path: "850:-670;876:-670;", geometry: beside_geometry)

    expect(seat(result)).to eq(role: [-60 - role_width, -7], mult: [-19, 15])
  end

  it "keeps the rightward tree seat when SOID and EOID follow Start and End" do
    result = reversed_labels(tree: "LV", soid: "MSMS", eoid: "PCPC")

    expect(seat(result)).to eq(role: [3, -23], mult: [3, 0])
  end
end
# rubocop:enable Metrics/BlockLength
