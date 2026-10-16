# frozen_string_literal: true

require "tempfile"

module BlankTagHelpers
  def qea_tag_document(values)
    database = build_test_database(qea_tag_rows(values))
    Ea::Sources::Qea::Adapter.new(database, "tags.qea").to_document
  end

  def qea_tag_rows(values)
    rows = Ea::Qea::Models
    {
      objects: [rows::EaObject.new(ea_object_id: 1, object_type: "Class", name: "Spatial References",
                                   ea_guid: "class", package_id: 1)],
      object_properties: values.map do |key, value|
        rows::EaObjectProperty.new(ea_object_id: 1, property: key, value: value)
      end,
      **qea_tag_diagram_rows
    }
  end

  def qea_tag_diagram_rows
    rows = Ea::Qea::Models
    {
      packages: [rows::EaPackage.new(package_id: 1, name: "P", ea_guid: "package")],
      diagrams: [rows::EaDiagram.new(diagram_id: 1, package_id: 1, diagram_type: "Logical",
                                     name: "D", ea_guid: "diagram", cx: 800, cy: 600)],
      diagram_objects: [rows::EaDiagramObject.new(diagram_id: 1, ea_object_id: 1, instance_id: 1,
                                                  rectleft: 10, rectright: 210, recttop: -10,
                                                  rectbottom: -210, objectstyle: "Tag=1;")]
    }
  end

  def xmi_tag_document
    Tempfile.create(["blank-tags", ".xmi"]) do |file|
      file.write(blank_tag_xmi)
      file.flush
      Ea::Sources::Xmi::Adapter.from_path(file.path)
    end
  end

  def blank_tag_xmi
    <<~XML
      <xmi:XMI xmlns:xmi="http://www.omg.org/spec/XMI/20131001" xmlns:uml="http://www.omg.org/spec/UML/20161101">
        <uml:Model name="Model">
          <packagedElement xmi:type="uml:Class" xmi:id="class" name="Spatial References"/>
        </uml:Model>
        <xmi:Extension extender="Enterprise Architect">
          <elements><element xmi:idref="class"><tags>
            <tag modelElement="class" name="VCSWKID"/>
            <tag modelElement="class" name="Empty" value=""/>
            <tag modelElement="class" name="WKID" value="0"/>
            <tag modelElement="class" name="HighPrecision" value="false"/>
          </tags></element></elements>
          <diagrams><diagram xmi:id="diagram">
            <properties name="D" type="Logical"/>
            <elements><element subject="class" geometry="Left=10;Top=10;Right=210;Bottom=210;" style="Tag=1;"/></elements>
          </diagram></diagrams>
        </xmi:Extension>
      </xmi:XMI>
    XML
  end

  def tag_svg(document, visible: nil)
    diagram = document.diagrams.first
    diagram.elements.first.show_tagged_values = visible unless visible.nil?
    svg = Ea::Svg::EaEmitter::Elements.new(diagram, model_index: document.index_by_id).render
    Nokogiri::XML("<svg>#{svg}</svg>").remove_namespaces!
  end
end
