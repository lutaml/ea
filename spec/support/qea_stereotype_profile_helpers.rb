# frozen_string_literal: true

module QeaStereotypeProfileHelpers
  def qea_stereotype_profile_document(name, fqname, application_name: name)
    object = Ea::Qea::Models::EaObject.new(ea_object_id: 1, object_type: "Class", name: "C", stereotype: name,
                                           ea_guid: "class", package_id: 1)
    xrefs = fqname ? [qea_stereotype_application(application_name, fqname)] : []
    database = build_test_database(qea_stereotype_placement.merge(objects: [object], xrefs: xrefs))
    Ea::Sources::Qea::Adapter.new(database, "stereotype-profile.qea").to_document
  end

  def qea_stereotype_application(name, fqname)
    Ea::Qea::Models::EaXref.new(xref_id: "stereotype", client: "class", name: "Stereotypes",
                                description: "@STEREO;Name=#{name};FQName=#{fqname};@ENDSTEREO;")
  end

  def qea_stereotype_placement
    rows = Ea::Qea::Models
    {
      packages: [rows::EaPackage.new(package_id: 1, name: "P", ea_guid: "package")],
      diagrams: [rows::EaDiagram.new(diagram_id: 1, package_id: 1, diagram_type: "Logical", name: "D",
                                     ea_guid: "diagram", cx: 800, cy: 600, styleex: "SuppressFOC=1;")],
      diagram_objects: [rows::EaDiagramObject.new(diagram_id: 1, ea_object_id: 1, instance_id: 1,
                                                  rectleft: 100, rectright: 300, recttop: -100, rectbottom: -300)]
    }
  end
end
