# frozen_string_literal: true

require "moxml"

module XmiStereotypeProfileHelpers
  include XmiConnectorEndHelpers

  CLASS_REF = "EAID_D2C7D9D6_79D4_479d_B46A_0F32EC6DB76B"

  def xmi_stereotype_document(name, fqname, application_name: name, prefix: "", keyword: nil)
    xml = Moxml.parse(basic_xmi_text)
    element = xml.at_xpath("//*[local-name()='elements']/*[@*[local-name()='idref']='#{CLASS_REF}']")
    element.at_xpath("./properties")["stereotype"] = name
    xrefs = element.at_xpath("./xrefs")
    if fqname
      xrefs["value"] = "#{prefix}$XREFPROP=$NAM=Stereotypes$NAM;$DES=" \
                       "@STEREO;Name=#{application_name};FQName=#{fqname};@ENDSTEREO;$DES;$ENDXREF;"
    end
    Array(keyword).each { |text| add_stereotype_keyword(xml, text) }
    parse_xmi(xml.to_xml)
  end

  def add_stereotype_keyword(xml, keyword)
    shape = xml.at_xpath("//*[@modelElement='#{CLASS_REF}']")
    label = xml.create_element("ownedElement")
    label["xmi:type"] = "umldi:UMLKeywordLabel"
    label["text"] = keyword
    shape.add_child(label)
  end

  def xmi_profile_result(document)
    classifier = document.classifiers.find { |entry| entry.id == CLASS_REF }
    [classifier.stereotype_refs, xmi_profile_texts(document)]
  end

  def xmi_profile_texts(document)
    diagram = document.diagrams.find do |candidate|
      candidate.elements.any? { |element| element.model_element_ref == CLASS_REF }
    end
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                    document: document, frame: true).render
    texts = Moxml.parse(svg).xpath("//*[local-name()='text']").map(&:text)
    texts.grep(/«/)
  end
end
