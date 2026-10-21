# frozen_string_literal: true

require "qea_end_label_helpers"
require "test_database_helper"

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
                                                                    document: document, frame: false, content_anchor: false).render
    qea_end_label_result(Nokogiri::XML(svg).remove_namespaces!, "0..1")
  end
end
