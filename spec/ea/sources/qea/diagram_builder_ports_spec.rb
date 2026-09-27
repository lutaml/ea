# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  # Real-row-shaped Structs — no doubles.
  FakeObjectRow = Struct.new(:rectleft, :recttop, :rectright, :rectbottom,
                             keyword_init: true)
  FakeConnectorRow = Struct.new(:start_object_id, :end_object_id)
  FakeDiagramRow = Struct.new(:diagram_id)

  let(:builder) { described_class.new(nil) }
  let(:diagram_row) { FakeDiagramRow.new(7) }
  let(:connector_row) { FakeConnectorRow.new(4, 3) }

  describe "#font_size_from" do
    it "converts genuinely custom fontsz values into points" do
      expect(builder.font_size_from(fontsz: "105")).to eq(11)
      expect(builder.font_size_from(fontsz: "70")).to eq(7)
    end

    it "treats default-marker fontsz values as use-default" do
      expect(builder.font_size_from(fontsz: "0")).to be_nil
      expect(builder.font_size_from(fontsz: "80")).to be_nil
      expect(builder.font_size_from(fontsz: "90")).to be_nil
      expect(builder.font_size_from(fontsz: "")).to be_nil
      expect(builder.font_size_from({})).to be_nil
    end
  end

  describe "#connection_port" do
    # Matches the source box used to derive the EA semantics: EA
    # docks a positive SX inward from the RIGHT edge and a positive
    # SY down from the TOP edge; negative values mirror to the
    # opposite edge. The target end mirrors the X side.
    let(:source_box) { placement(179, -669, 494, -467) }
    let(:target_box) { placement(597, -579, 923, -467) }

    def placement(left, top, right, bottom)
      FakeObjectRow.new(rectleft: left, recttop: top,
                        rectright: right, rectbottom: bottom)
    end

    before do
      allow(builder).to receive(:diagram_object_placement).with(7, 4)
                                                          .and_return(source_box)
      allow(builder).to receive(:diagram_object_placement).with(7, 3)
                                                          .and_return(target_box)
    end

    it "ray-casts the source port from the center through the offset" do
      port = builder.connection_port(diagram_row, connector_row,
                                     :source, { sx: 5, sy: 38 })
      # flipped source bounds x=179 y=467 w=315 h=202, center (336.5,568);
      # direction (5,-38) exits the top edge at t = 101/38
      expect([port.x, port.y]).to eq([350, 467])
    end

    it "ray-casts downward when the offset points down" do
      port = builder.connection_port(diagram_row, connector_row,
                                     :source, { sx: -5, sy: -29 })
      # direction (-5, 29) exits the bottom edge at t = 101/29
      expect([port.x, port.y]).to eq([319, 669])
    end

    it "ray-casts the target port through its own center offset" do
      port = builder.connection_port(diagram_row, connector_row,
                                     :target, { ex: 5, ey: 32 })
      # flipped target bounds x=597 y=467 w=326 h=112, center (760,523);
      # direction (5,-32) exits the top edge at t = 56/32
      expect([port.x, port.y]).to eq([769, 467])
    end

    it "returns nil when the geometry carries no offsets" do
      expect(builder.connection_port(diagram_row, connector_row,
                                     :source, {})).to be_nil
    end
  end

  describe "end-to-end docking against the basic.qea fixture" do
    let(:path) { File.expand_path("../../../fixtures/basic.qea", __dir__) }
    let(:document) do
      database = Ea.parse(path)
      Ea::Sources::Qea::Adapter.new(database, path).to_document
    end

    it "docks each connector's waypoint endpoints at its ports" do
      checked = 0
      document.diagrams.flat_map(&:connectors).each do |connector|
        next unless connector.source_port || connector.target_port

        waypoints = connector.waypoints.map(&:position)
        expect(waypoints.size).to be >= 2
        if connector.source_port
          expect([waypoints.first.x, waypoints.first.y])
            .to eq([connector.source_port.x, connector.source_port.y])
        end
        if connector.target_port
          expect([waypoints.last.x, waypoints.last.y])
            .to eq([connector.target_port.x, connector.target_port.y])
        end
        checked += 1
      end
      expect(checked).to be > 10
    end
  end
end
