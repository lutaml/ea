# frozen_string_literal: true

require "nokogiri"
require "tempfile"

# Actual diagram extract from lutaml-uml 1.0.2 examples/xmi/20251010_current_plateau_v5.1.xmi.
# Source SHA256: 695e16dda5c749a01e52a5630f1aa9c51744ba7bd47be4406ca0f104f64ba96c.
# Original UMLDI lines 31094-31209 and EA diagram lines 115204-115235 are retained verbatim.
module Umldi2a339928Helpers
  CASES = {
    "lod0RoofEdge" => {
      association: "EAID_1569565C_CFA4_4c82_B472_8D822A5E9206",
      property: "EAID_src69565C_CFA4_4c82_B472_8D822A5E9206",
      bounds: { x: 636, y: 458, width: 68, height: 25 },
      llt_width: 94, route: [[764, 461], [558, 461]], ports: [[872, 461], [193, 500]]
    },
    "lod0FootPrint" => {
      association: "EAID_BEAA26FD_80FD_4c1a_9F80_908116F569FB",
      property: "EAID_srcAA26FD_80FD_4c1a_9F80_908116F569FB",
      bounds: { x: 637, y: 511, width: 67, height: 25 },
      llt_width: 88, route: [[764, 532], [558, 532]], ports: [[764, 532], [274, 666]]
    }
  }.freeze

  IDENTITY_CHANGES = {
    "wrong association" => lambda do |xml, data|
      xml.at_xpath("//*[@xmi:id='#{data[:property]}']")["association"] = "unrelated"
    end,
    "missing memberEnd" => lambda do |xml, data|
      xml.xpath("//*[local-name()='memberEnd'][@xmi:idref='#{data[:property]}']").remove
    end,
    "wrong memberEnd" => lambda do |xml, data|
      member = xml.at_xpath("//*[local-name()='memberEnd'][@xmi:idref='#{data[:property]}']")
      member["xmi:idref"] = "unrelated_property"
    end,
    "duplicate edge" => lambda do |xml, data|
      edge = xml.at_xpath("//*[@modelElement='#{data[:association]}'][@source]")
      edge.add_next_sibling(edge.dup)
    end
  }.freeze

  def held_out_xml
    Nokogiri::XML(File.read(fixtures_path("issue135_route_style/2a339928-source-roles.xmi")))
  end

  def held_out_connector(xml, association)
    Tempfile.create(["2a-source-role", ".xmi"]) do |file|
      file.write(xml.to_xml)
      file.flush
      connectors = Ea::Sources::Xmi::Adapter.from_path(file.path).diagrams.first.connectors
      connectors.find { |connector| connector.relationship_ref == association }
    end
  end
end
