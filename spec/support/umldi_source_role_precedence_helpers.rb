# frozen_string_literal: true

require_relative "xmi_0be_label_precedence_helpers"

module UmldiSourceRolePrecedenceHelpers
  include Xmi0beLabelPrecedenceHelpers

  def source_role_connector(identity: true)
    xml = source_role_xml(identity)
    Tempfile.create(["0be-source-role-precedence", ".xmi"]) do |file|
      file.write(xml.to_xml)
      file.flush
      Xmi0beBoundedByLabelsHelpers.source(file.path).last.first
    end
  end

  def source_role_xml(identity)
    xml = bounded_by_xml(nil, false)
    association = Xmi0beBoundedByLabelsHelpers::ASSOCIATIONS.first
    placement = xml.at_xpath("//*[@subject='#{association}']")
    placement["geometry"] += "$LLT=CX=57:CY=25:OX=17:OY=-9;$LLB=CX=15:CY=13:OX=0:OY=0;"
    unless identity
      property_id = xml.at_xpath("//*[@modelElement='#{association}']/ownedElement")["modelElement"]
      xml.xpath("//*[@xmi:id='#{property_id}']").each { |node| node["association"] = "unrelated_association" }
    end
    xml
  end
end
