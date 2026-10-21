# frozen_string_literal: true

require "nokogiri"
require "tempfile"

module UmldiTargetBoundsPrecedenceHelpers
  FIXTURE = "issue135_route_style/88d0-property-bounds.xmi"
  EXTERNAL = "EAID_98F26EAF_7E3C_48b2_AAE7_4769CF1AAFD6"
  XAL = "EAID_3235AFCD_ABFF_4603_9B4E_14BAEC8D9ECA"
  EXTERNAL_BOX = { x: 767, y: 288, width: 86, height: 13 }.freeze
  XAL_BOX = { x: 895, y: 176, width: 55, height: 13 }.freeze

  def self.adapt(path = fixtures_path(FIXTURE))
    Ea::Sources::Xmi::Adapter.from_path(path)
  end

  def self.connector(document, id)
    document.diagrams.first.connectors.find { |item| item.relationship_ref == id }
  end

  def self.role_positions(document)
    svg = Ea::Svg::EaEmitter::Document.new(
      document.diagrams.first, model_index: document.index_by_id, document: document,
      frame: true
    ).render
    Nokogiri::XML(svg).xpath("//*[local-name()='text']").to_h do |node|
      [node.text, [node["x"].to_f, node["y"].to_f]]
    end.slice("+externalReference", "+xalAddress")
  end

  def self.with_bounds(document, external: nil, xal: nil)
    connector(document, EXTERNAL).umldi_label_bounds = external ? { target_role: external } : {}
    connector(document, XAL).umldi_label_bounds = xal ? { target_role: xal } : {}
    document
  end

  def self.route_paths(document)
    svg = Ea::Svg::EaEmitter::Document.new(
      document.diagrams.first, model_index: document.index_by_id, document: document,
      frame: true
    ).render
    Nokogiri::XML(svg).xpath("//*[local-name()='path']").map { |node| node["d"] }
  end

  def self.without_declared_properties
    xml = Nokogiri::XML(File.read(fixtures_path(FIXTURE)))
    xml.xpath("//*[@association]").each { |node| node.remove_attribute("association") }
    Tempfile.create(["88d0-undeclared", ".xmi"]) do |file|
      file.write(xml.to_xml)
      file.flush
      yield adapt(file.path)
    end
  end
end
