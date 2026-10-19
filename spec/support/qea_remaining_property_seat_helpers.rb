# frozen_string_literal: true

module QeaRemainingPropertySeatHelpers
  def remaining_target_property(record, stereotype: "property", alignment: 1)
    tables = qea_end_label_tables(record[:path], record[:boxes], [270, 235, 243, 156], [440, 456, 150, 80],
                                  { role: record[:role], mult: "0..1", end: :target,
                                    stereotype: stereotype, alignment: alignment, style: record[:style] })
    link = tables[:diagram_links].first
    geometry = link.geometry.sub("LRT=CX=19:CY=16", "LRT=CX=85:CY=35")
                   .sub("LRB=CX=19:CY=16", "LRB=CX=21:CY=18")
    geometry = geometry.sub("SX=0;SY=0;EX=0;EY=0;EDGE=1;", record[:geometry]) if record[:geometry]
    link.geometry = geometry
    remaining_property_result(tables, "0..1")
  end

  def remaining_stair_property(record, stereotype: "property", style: "Mode=3;LWidth=0;TREE=V;", alignment: 1)
    tables = qea_end_label_tables(record[:path], record[:boxes], [443, 240, 184, 70], record[:target],
                                  { role: record[:role], mult: "0..*", stereotype: stereotype,
                                    alignment: alignment, style: style })
    tables[:connectors].first.connector_type = "Aggregation"
    link = tables[:diagram_links].first
    link.geometry = link.geometry.sub("LLT=CX=19:CY=16", "LLT=CX=181:CY=35")
                        .sub("LLB=CX=19:CY=16", "LLB=CX=19:CY=18")
    remaining_property_result(tables, "0..*")
  end

  def remaining_property_result(tables, mult)
    document = Ea::Sources::Qea::Adapter.new(build_test_database(**tables), "remaining-property.qea").to_document
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false).render
    qea_end_label_result(Nokogiri::XML(svg).remove_namespaces!, mult)
  end
end
