# frozen_string_literal: true

require "spec_helper"
require "set"
require "ea/sources/qea/context_diagram_support"

RSpec.describe Ea::Sources::Qea::ContextDiagramSupport do
  # Real row-shaped Structs and a hand-rolled container — no doubles.
  # Namespaced: other specs define their own top-level Fake*Row
  # structs and whichever loads last would win.
  module ContextSpecRows
    DiagramRow = Struct.new(:diagram_id, :name, :styleex, keyword_init: true)
    PlacementRow = Struct.new(:ea_object_id, keyword_init: true)
    ObjectRow = Struct.new(:object_id, :name, keyword_init: true)
    LinkRow = Struct.new(:connectorid, :hidden, keyword_init: true)
    ConnectorRow = Struct.new(:connector_id, :connector_type,
                              :start_object_id, :end_object_id,
                              keyword_init: true)

    Database = Struct.new(:objects, :connectors, :diagram_objects,
                          :diagram_links) do
      def diagram_objects_for(id)
        diagram_objects.select { |p| p.diagram_id == id }
      end

      def diagram_links_for(id)
        diagram_links.select { |l| l.diagram_id == id }
      end

      def find_object(id)
        objects.find { |o| o.object_id == id }
      end

      def find_connector(id)
        connectors.find { |c| c.connector_id == id }
      end

      def collections
        { connectors: connectors }
      end
    end
  end

  ContextDiagramRow = ContextSpecRows::DiagramRow
  ContextPlacementRow = ContextSpecRows::PlacementRow
  ContextObjectRow = ContextSpecRows::ObjectRow
  ContextLinkRow = ContextSpecRows::LinkRow
  ContextConnectorRow = ContextSpecRows::ConnectorRow
  ContextDatabase = ContextSpecRows::Database

  def placement_row(diagram_id, object_id)
    row = ContextPlacementRow.new(ea_object_id: object_id)
    row.define_singleton_method(:diagram_id) { diagram_id }
    row
  end

  def link_row(diagram_id, connector_id, hidden: 0)
    row = ContextLinkRow.new(connectorid: connector_id, hidden: hidden)
    row.define_singleton_method(:diagram_id) { diagram_id }
    row
  end

  def object_row(id, name)
    ContextObjectRow.new(object_id: id, name: name)
  end

  def connector_row(id, type, start_id, end_id)
    ContextConnectorRow.new(connector_id: id, connector_type: type,
                         start_object_id: start_id, end_object_id: end_id)
  end

  subject(:support) { described_class }

  describe ".context?" do
    it "matches the prefix case-insensitively" do
      row = ContextDiagramRow.new(diagram_id: 1, name: "Context diagram: Bag",
                               styleex: "")
      expect(support.context?(row)).to be(true)
    end

    it "rejects other diagrams" do
      row = ContextDiagramRow.new(diagram_id: 1, name: "Main", styleex: "")
      expect(support.context?(row)).to be(false)
    end
  end

  describe ".package_context" do
    it "parses Clients and Suppliers variants" do
      row = ContextDiagramRow.new(diagram_id: 1,
                               name: "Context Diagram: Package Clients of X",
                               styleex: "")
      expect(support.package_context(row))
        .to eq("variant" => "Clients", "focal_name" => "X")
    end

    it "keeps the focal name verbatim, including leading spaces" do
      row = ContextDiagramRow.new(
        diagram_id: 1,
        name: "Context Diagram: Package Suppliers of  Topology Simple",
        styleex: ""
      )
      expect(support.package_context(row))
        .to eq("variant" => "Suppliers", "focal_name" => " Topology Simple")
    end

    it "returns nil for element contexts" do
      row = ContextDiagramRow.new(diagram_id: 1, name: "Context Diagram: Bag",
                               styleex: "")
      expect(support.package_context(row)).to be_nil
    end
  end

  describe ".element_regenerate?" do
    it "is false for package contexts regardless of SuppressFOC" do
      row = ContextDiagramRow.new(
        diagram_id: 1,
        name: "Context Diagram: Package Clients of X",
        styleex: "SuppressFOC=0"
      )
      expect(support.element_regenerate?(row)).to be(false)
    end

    it "is false when SuppressFOC=1 freezes the stored links" do
      row = ContextDiagramRow.new(diagram_id: 1, name: "Context Diagram: Bag",
                               styleex: "SuppressFOC=1")
      expect(support.element_regenerate?(row)).to be(false)
    end

    it "is true when SuppressFOC=0 or absent" do
      absent = ContextDiagramRow.new(diagram_id: 1, name: "Context Diagram: Bag",
                                  styleex: "")
      zero = ContextDiagramRow.new(diagram_id: 1, name: "Context Diagram: Bag",
                                styleex: "SuppressFOC=0")
      expect(support.element_regenerate?(absent)).to be(true)
      expect(support.element_regenerate?(zero)).to be(true)
    end
  end

  describe ".autoline_candidates" do
    # Focal package 10 placed; clients 11 and 12 carry dependencies
    # into the focal; 11 already has a visible link row; 13 is a
    # supplier (focal -> 13) and must not appear on a Clients
    # diagram; 14 is off-diagram.
    let(:database) do
      ContextDatabase.new(
        [object_row(10, "Focal"), object_row(11, "Client A"),
         object_row(12, "Client B"), object_row(13, "Supplier"),
         object_row(14, "Off Diagram")],
        [connector_row(101, "Dependency", 11, 10),
         connector_row(102, "Dependency", 12, 10),
         connector_row(103, "Dependency", 12, 10),
         connector_row(104, "Dependency", 10, 13)],
        [placement_row(7, 10), placement_row(7, 11),
         placement_row(7, 12), placement_row(7, 13)],
        [link_row(7, 101, hidden: 0), link_row(7, 104, hidden: 1)]
      )
    end

    let(:diagram_row) do
      ContextDiagramRow.new(diagram_id: 7,
                         name: "Context Diagram: Package Clients of Focal",
                         styleex: "")
    end

    it "returns one candidate per placed client without a visible link" do
      expect(support.autoline_candidates(diagram_row, database).keys)
        .to contain_exactly(12)
    end

    it "does not synthesize when the focal is not placed exactly once" do
      database.diagram_objects.reject! { |p| p.ea_object_id == 10 }
      expect(support.autoline_candidates(diagram_row, database)).to be_empty
    end
  end

  describe ".regenerated_element_connectors" do
    # Focal 10; neighbours 11 and 12 (linked to the focal); 13 is
    # two hops away. 201 has a hidden link row and still
    # regenerates; 202 is ring1-ring2 (draws); 203 is
    # ring1-ring1 (skipped, NT_Network's Turn-Junction web);
    # 204 is ring1-ring2 (draws); Nesting never draws or joins
    # the neighbourhood; 206 is the focal's self-loop.
    let(:database) do
      ContextDatabase.new(
        [object_row(10, "Focal"), object_row(11, "N1"),
         object_row(12, "N2"), object_row(13, "Far")],
        [connector_row(201, "Association", 10, 11),
         connector_row(202, "Generalization", 11, 13),
         connector_row(203, "Association", 11, 12),
         connector_row(204, "Association", 12, 13),
         connector_row(205, "Nesting", 10, 12),
         connector_row(206, "Association", 10, 10),
         connector_row(207, "Association", 10, 12)],
        [placement_row(7, 10), placement_row(7, 11),
         placement_row(7, 12), placement_row(7, 13)],
        [link_row(7, 201, hidden: 1)]
      )
    end

    let(:diagram_row) do
      ContextDiagramRow.new(diagram_id: 7, name: "Context Diagram: Focal",
                         styleex: "SuppressFOC=0")
    end

    it "draws the focal star and ring1-ring2, skips ring1-ring1" do
      expect(support.regenerated_element_connectors(diagram_row, database)
                     .map(&:connector_id))
        .to contain_exactly(201, 202, 204, 206, 207)
    end

    it "returns nothing when SuppressFOC=1" do
      frozen = ContextDiagramRow.new(diagram_id: 7, name: "Context Diagram: Focal",
                                  styleex: "SuppressFOC=1")
      expect(support.regenerated_element_connectors(frozen, database))
        .to be_empty
    end
  end

  describe ".focal_element_id fallback" do
    # Stale title: no placed object is named "Old Name". The most
    # connected placed element (10, three in-diagram links) wins
    # over the globally connected 12.
    let(:database) do
      ContextDatabase.new(
        [object_row(10, "Renamed"), object_row(11, "N1"),
         object_row(12, "Hub")],
        [connector_row(301, "Association", 10, 11),
         connector_row(302, "Association", 11, 10),
         connector_row(303, "Association", 10, 10),
         connector_row(304, "Association", 12, 999),
         connector_row(305, "Association", 12, 998),
         connector_row(306, "Association", 12, 997)],
        [placement_row(7, 10), placement_row(7, 11), placement_row(7, 12)],
        []
      )
    end

    let(:diagram_row) do
      ContextDiagramRow.new(diagram_id: 7, name: "Context Diagram: Old Name",
                         styleex: "SuppressFOC=0")
    end

    it "falls back to the placed element most connected within the diagram" do
      expect(support.focal_element_id(diagram_row, database,
                                      support.placed_object_ids_for(diagram_row,
                                                                    database)))
        .to eq(10)
    end
  end
end
