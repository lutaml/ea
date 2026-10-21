# frozen_string_literal: true

module LabelDownwardFinalHelpers
  def downward_final_records
    [{ role: "parent", source: [211, 59, 330, 142], target: [271, 299, 202, 121],
       offset: [49, 14], width: "2", dock: "SX=79;SY=-1;EX=83;EY=-1;EDGE=3;", delta: [-51, 29] },
     { role: "shape", source: [1186, 658, 108, 175], target: [1117, 873, 244, 99],
       offset: [146, -3], width: "0", dock: "SX=0;SY=0;EX=0;EY=0;EDGE=3;", delta: [49, 12] }]
  end

  def downward_final_labels(record, **options)
    ends = { role: record[:role], mult: "0..1", alignment: 0,
             style: "Mode=3;LWidth=#{record[:width]};" }.merge(options)
    boxes = { "LLT" => record[:offset], "LLB" => [0, 0] }
    tables = qea_end_label_tables("", boxes, record[:source], record[:target], ends)
    tables[:diagram_links].first.geometry = downward_final_geometry(boxes, record[:dock])
    render_downward_final(tables)
  end

  def downward_final_geometry(boxes, dock)
    qea_end_label_geometry(boxes)
      .sub("SX=0;SY=0;EX=0;EY=0;EDGE=1;", dock)
      .sub("LLT=CX=19:CY=16", "LLT=CX=57:CY=31")
  end

  def render_downward_final(tables)
    document = Ea::Sources::Qea::Adapter.new(build_test_database(**tables), "downward-final.qea").to_document
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false, content_anchor: false).render
    qea_end_label_result(Nokogiri::XML(svg).remove_namespaces!, "0..1")
  end
end
