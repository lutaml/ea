# frozen_string_literal: true

require "nokogiri"
require "tempfile"

module UmlDiLabelBoundsFallbackHelpers
  def self.render_without_extension_boxes(path)
    xml = stripped_xml(path)
    Tempfile.create(["ea135-umldi-bounds", ".xmi"]) do |file|
      file.write(xml.to_xml)
      file.flush
      result_from_path(file.path)
    end
  end

  def self.stripped_xml(path)
    xml = Nokogiri::XML(File.read(path))
    element = xml.at_xpath(
      "//*[local-name()='element' and @subject='EAID_3677D889_F04B_4fb8_9651_5D1D972FBCD6']"
    )
    element["geometry"] = element["geometry"].gsub(/(?:\$LLB|LLT)=[^;]*;/, "")
    xml
  end

  def self.result_from_path(path)
    document = Ea::Sources::Xmi::Adapter.from_path(path)
    diagram = document.diagrams.first
    connector = connector_for(diagram)
    result_for(document, diagram, connector)
  end

  def self.result_for(document, diagram, connector)
    texts = render_texts(document, diagram, connector)
    bounds = connector.umldi_label_bounds
    label_boxes = connector.label_boxes
    connector.umldi_label_bounds = {}
    baseline_texts = render_texts(document, diagram, connector)
    { bounds: bounds, label_boxes: label_boxes, texts: texts,
      fallback_role_count: role_count(texts), baseline_role_count: role_count(baseline_texts) }
  end

  def self.role_count(texts)
    texts.count { |node| node.text == "+indoorOpeningAttribute" }
  end

  def self.explicit_box_state(path)
    document = Ea::Sources::Xmi::Adapter.from_path(path)
    connector = connector_for(document.diagrams.first)
    [connector.label_boxes, connector.umldi_label_bounds]
  end

  def self.connector_for(diagram)
    diagram.connectors.find { |item| item.relationship_ref.include?("3677D889") }
  end

  def self.render_texts(document, diagram, connector)
    render_diagram = diagram.dup
    render_diagram.connectors = [connector]
    svg = Ea::Svg::EaEmitter::Document.new(
      render_diagram, model_index: document.index_by_id, document: document,
      frame: true
    ).render
    Nokogiri::XML(svg).xpath("//*[local-name()='text']")
  end

  def self.label_position(texts, label)
    node = texts.find { |item| item.text == label }
    [node["x"], node["y"]]
  end
end
