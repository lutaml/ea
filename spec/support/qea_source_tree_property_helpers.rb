# frozen_string_literal: true

module QeaSourceTreePropertyHelpers
  include QeaEndLabelHelpers

  BOXES = { "LRT" => [3, 26], "LRB" => [15, -29] }.freeze

  def tree_property_labels(tree: "LH", offset: 0, stereotype: "property")
    ends = { role: "lod0Geometry", mult: "0..1", stereotype: stereotype,
             style: "Mode=3;LWidth=2;TREE=#{tree};" }
    tables = qea_end_label_tables("", BOXES, [141, 289, 100, 80], [370, 276, 269, 200], ends)
    tables[:diagram_links].first.geometry = tree_property_geometry(offset)
    render_tree_property(tables)
  end

  def tree_property_geometry(offset)
    boxes = offset.zero? ? BOXES : BOXES.merge("LLT" => [offset, 0])
    qea_end_label_geometry(boxes).sub("SX=0;SY=0;EX=0;EY=0;EDGE=1;",
                                      "EDGE=4;SX=49;SY=17;EX=0;EY=0;")
  end

  def render_tree_property(tables)
    document = Ea::Sources::Qea::Adapter.new(build_test_database(**tables), "tree-property.qea").to_document
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false, content_anchor: false).render
    qea_end_label_result(Nokogiri::XML(svg).remove_namespaces!, "0..1")
  end
end
