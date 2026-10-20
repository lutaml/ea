# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.shared_context "basic XMI route label corpus" do
  include XmiBasicRouteLabelHelpers

  before(:context) do
    @basic_route_label_document = QeaBridgeCorpusHelpers.document_for(
      Ea::Sources::Xmi::Adapter, "spec/fixtures/basic.xmi"
    )
  end
end

RSpec.describe Ea::Svg::EaEmitter::Document, "basic XMI named object links" do
  include_context "basic XMI route label corpus"

  it "renders both named links between object instances" do
    text = basic_route_label_text("157826AA")

    aggregate_failures do
      expect(text.count("Link A")).to eq(1)
      expect(text.count("Link B")).to eq(1)
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Document, "basic XMI unresolved extension routes" do
  include_context "basic XMI route label corpus"

  it "retains saved UMLDI routes when stale endpoint identifiers prevent extension routing" do
    routes = [
      ["157826AA", "0273F609", [[182, 180], [182, 135], [329, 135]]],
      ["157826AA", "97A0AE9F", [[178, 255], [178, 302], [329, 302]]],
      ["14E9F5FD", "DBD4BDC6", [[685, 286], [685, 246], [460, 246], [460, 196]]],
      ["14E9F5FD", "4901800B", [[231, 279], [231, 246], [460, 246], [460, 196]]]
    ]

    aggregate_failures do
      routes.each do |diagram, relationship, expected|
        connector = basic_route_label_connector(diagram, relationship)
        points = connector.waypoints.map { |point| [point.position.x, point.position.y] }
        expect(points).to eq(expected), "saved route for #{relationship}"
      end
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Document, "basic XMI vertical tree trunk" do
  include_context "basic XMI route label corpus"

  it "omits only the zero-length segment of a resolved vertical tree trunk" do
    diagram = basic_route_label_diagram("14E9F5FD")
    connector = basic_route_label_connector("14E9F5FD", "1B5CC9EE")
    edges = Ea::Sources::Xmi::DiagramBuilder::UmldiEdges.new("spec/fixtures/basic.xmi")

    aggregate_failures do
      expect(edges.route_for(diagram.id, connector.relationship_ref))
        .to eq([[460, 282], [460, 246], [460, 246], [460, 196]])
      # Native's trunk keeps row 246 and both docks, without the repeated vertex.
      expect(connector.waypoints.map { |point| [point.position.x, point.position.y] })
        .to eq([[460, 282], [460, 246], [460, 196]])
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Document, "basic XMI matching text preservation" do
  include_context "basic XMI route label corpus"

  it "preserves the complete visible text of the four already matching diagrams" do
    expected = {
      "B0DDB85D" => ["class Signals", "Signal A", "Signal B", "Signal C", "«signal»", "«signal»", "«signal»"],
      "D14AA320" => ["object Starter Object Diagram", "Object A", "Object B", "Link A"],
      "3B8BD087" => ["object Basic Object Diagram with Value Specification", "Object A", "Object B", "Link A",
                     "Variable A = Value One", "Variable B = Value One"],
      "6E95B74E" => ["class Basic Class Diaram with Roles", "Class A", "Class B", "Name A",
                     "+role a", "+role b", "0..*", "0..*"]
    }

    aggregate_failures do
      expected.each do |diagram, text|
        expect(basic_route_label_text(diagram)).to contain_exactly(*text)
      end
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Document, "basic XMI instance link text parity" do
  include_context "basic XMI route label corpus"

  it "matches the complete native instance body plus the diagram frame title" do
    expected = [
      "object Objects as Instances of Classes", "Link A", "Link B",
      "Object 01 / roleOne: Class A", "Object 02 / roleTwo: Class B", "Object 03 / roleTwo: Class B"
    ] + (["(from Objects)", "attribute One = Value One", "attribute Two = Value Two"] * 3)

    expect(basic_route_label_text("157826AA")).to contain_exactly(*expected)
  end
end

RSpec.describe Ea::Svg::EaEmitter::Document, "basic XMI unnamed link text parity" do
  include_context "basic XMI route label corpus"

  it "matches the complete native value-specification body without phantom association names" do
    expected = [
      "object Object with Value Specifications", "attributeTwo <= valueTwo",
      "Object 01 / roleOne: Class A", "Object 02 / roleTwo: Class B", "Object 03 / roleThree1: Class C",
      "Object 04 / roleThree2: Class C", "Object 05 / roleThree3: Class C"
    ] + (["(from Objects)", "attributeOne = valueOne"] * 5)
    expected += ["attributeThree = valueThree", "attributeTwo = valueTwo"] * 4

    expect(basic_route_label_text("14E9F5FD")).to contain_exactly(*expected)
  end
end
