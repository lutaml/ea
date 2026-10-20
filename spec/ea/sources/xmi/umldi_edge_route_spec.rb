# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI connector routes from UMLDI edges" do
  include QeaBridgeCorpusHelpers
  include XmiBendSignHelpers
  include XmiUmldiEdgeHelpers
  include XmiLabelBoxHelpers

  describe Ea::Sources::Xmi::DiagramBuilder::UmldiEdges do
    it "returns the ordered waypoints of the connector's only edge" do
      expect(umldi_route(umldi_edge("C1", [[10, 5], [10, 40], [30, 40]]), "C1")).to eq([[10, 5], [10, 40], [30, 40]])
    end

    it "has no route when two edges of the diagram draw the same connector" do
      edges = umldi_edge("C1", [[0, 0], [0, 9]]) + umldi_edge("C1", [[5, 0], [5, 9]])
      expect(umldi_route(edges, "C1")).to be_nil
    end

    it "has no route for an edge with a single waypoint" do
      expect(umldi_route(umldi_edge("C1", [[0, 0]]), "C1")).to be_nil
    end

    it "returns the source and target of the connector's only edge" do
      edge = %(<ownedElement type="umldi:UMLEdge" modelElement="C1" source="S" target="T"/>)
      expect(umldi_ends(edge, "C1")).to eq(%w[S T])
    end

    it "has no ends when two edges of the diagram draw the same connector" do
      edge = %(<ownedElement type="umldi:UMLEdge" modelElement="C1" source="S" target="T"/>)
      expect(umldi_ends(edge + edge, "C1")).to be_nil
    end

    it "has no route for a connector without an edge" do
      expect(umldi_route(umldi_edge("C1", [[0, 0], [0, 9]]), "C2")).to be_nil
    end
  end

  it "routes a basic connector whose placement endpoints are unresolved along its UMLDI edge" do
    connector = basic_diagram_connector(Ea::Sources::Xmi::Adapter, "spec/fixtures/basic.xmi",
                                        "Starter Object Diagram", "1137B03A-C00A-443b-A3A8-D5CF6A7AFF13")
    expect(connector.waypoints.map { |w| [w.position.x, w.position.y] }).to eq([[190, 125], [315, 125]])
  end

  context "with the plateau corpus" do
    it "routes E7FFECEB along its UMLDI edge" do
      expect(plateau_xmi_points("73025C5A-08FC-47ff-AB2F-C7F79CF54B41", "E7FFECEB-996C-45b0-8E47-A56B4834C7DF"))
        .to eq([[620, 640], [620, 700]])
    end

    it "routes d147 connector 485 along its UMLDI edge" do
      expect(plateau_xmi_points("E7AABA98-2450-4986-9736-DCCAF0108C50", "A9F15FEA-A44A-488C-B8CF-CB097D4B009A"))
        .to eq([[1073, 442], [1073, 568]])
    end

    it "routes d147 connector 808 along its UMLDI edge" do
      expect(plateau_xmi_points("E7AABA98-2450-4986-9736-DCCAF0108C50", "691EB32D-B315-430F-BA1E-7A91E05BC70F"))
        .to eq([[1234, 568], [1234, 501]])
    end

    it "routes the empty-Path d148 connector 0398A9E6 along its UMLDI edge, not the QEA ray ports" do
      expect(plateau_xmi_points("00C5C772-5A03-434f-BF30-AC37542A1AAC", "0398A9E6-E19E-4231-A860-45D0C72E9A0E"))
        .to eq([[401, 1121], [949, 1121]])
    end

    it "keeps the stored-bend route of d147 connector 848" do
      expect(plateau_xmi_points("E7AABA98-2450-4986-9736-DCCAF0108C50", "AD628304-78EA-4E0B-B4AF-39769E39D20E"))
        .to eq([[1433, 1199], [1433, 543], [804, 543]])
    end
  end
end
