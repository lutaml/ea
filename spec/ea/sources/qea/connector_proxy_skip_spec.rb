# frozen_string_literal: true

require "spec_helper"

# EA never draws the ProxyConnector stub that anchors an association class.
RSpec.describe "QEA ProxyConnector placements" do
  def rendered_rects(object_type) # rubocop:disable Metrics/MethodLength
    rows = Ea::Qea::Models
    database = build_test_database(
      objects: [rows::EaObject.new(ea_object_id: 1, object_type: object_type, name: "Stub",
                                   ea_guid: "stub", package_id: 1)],
      packages: [rows::EaPackage.new(package_id: 1, name: "P", ea_guid: "package")],
      diagrams: [rows::EaDiagram.new(diagram_id: 1, package_id: 1, diagram_type: "Logical",
                                     name: "D", ea_guid: "diagram", cx: 800, cy: 600)],
      diagram_objects: [rows::EaDiagramObject.new(diagram_id: 1, ea_object_id: 1, instance_id: 1,
                                                  rectleft: 10, rectright: 24, recttop: -10, rectbottom: -24)]
    )
    document = Ea::Sources::Qea::Adapter.new(database, "proxy.qea").to_document
    svg = Ea::Svg::EaEmitter::Document.new(
      document.diagrams.first, model_index: document.index_by_id,
      document: document, frame: false, content_anchor: false
    ).render
    Nokogiri::XML(svg).remove_namespaces!.xpath("//rect").size
  end

  it "draws one rectangle fewer for a ProxyConnector placement than for a class" do
    expect(rendered_rects("ProxyConnector")).to eq(rendered_rects("Class") - 1)
  end

  it "still draws the same placement for another object type" do
    expect(rendered_rects("Class")).to be > 0
  end
end
