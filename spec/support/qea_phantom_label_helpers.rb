# frozen_string_literal: true

module QeaPhantomLabelHelpers
  def qea_phantom_labels(role, upward: false)
    tables = qea_phantom_tables(role, upward)
    database = build_test_database(**tables)
    document = Ea::Sources::Qea::Adapter.new(database, "phantom-labels.qea").to_document
    svg = Ea::Svg::EaEmitter::Document.new(document.diagrams.first, model_index: document.index_by_id,
                                                                    document: document, frame: false, content_anchor: false).render
    qea_end_label_result(Nokogiri::XML(svg).remove_namespaces!, "0..1")
  end

  def qea_phantom_tables(role, upward)
    source = upward ? [100, 300, 200, 100] : [500, 300, 200, 100]
    target = upward ? [100, 100, 200, 100] : [100, 300, 200, 100]
    tables = qea_end_label_tables("", {}, source, target, { role: role, mult: "0..1" })
    tables[:diagram_links] = []
    tables
  end
end
