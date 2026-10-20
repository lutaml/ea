# frozen_string_literal: true

require "xmi"

module XmiNestedClassifierHelpers
  XML = <<~XML
    <xmi:XMI xmlns:xmi="http://schema.omg.org/spec/XMI/2.1" xmlns:uml="http://schema.omg.org/spec/UML/2.1">
      <uml:Model xmi:type="uml:Model" xmi:id="model" name="Model">
        <packagedElement xmi:type="uml:Class" xmi:id="root" name="Root"/>
        <packagedElement xmi:type="uml:Package" xmi:id="package" name="Package">
          <packagedElement xmi:type="uml:Class" xmi:id="owner" name="Owner">
            <nestedClassifier xmi:type="uml:Class" xmi:id="child" name="Child">
              <generalization xmi:type="uml:Generalization" xmi:id="generalization" general="root"/>
              <packagedElement xmi:type="uml:Association" xmi:id="association">
                <memberEnd xmi:idref="child"/>
                <memberEnd xmi:idref="root"/>
              </packagedElement>
            </nestedClassifier>
          </packagedElement>
          <packagedElement xmi:type="uml:Package" xmi:id="subpackage" name="Subpackage">
            <packagedElement xmi:type="uml:Class" xmi:id="other" name="Other"/>
          </packagedElement>
        </packagedElement>
      </uml:Model>
    </xmi:XMI>
  XML
  def nested_classifier_document
    Ea::Sources::Xmi::Adapter.new(Xmi::Sparx::Root.parse_xml(XML)).to_document
  end
end
