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
    it "rounds fontsz through GDI pixel metrics" do
      # EA creates the GDI font at floor(tenths * 96 / 720) pixels,
      # then reports floor(pixels * 72 / 96) points. Corpus anchors:
      # 0D31AED1 (all-100 elements) publishes 9pt, 4EBDE645's 90 =
      # 9pt, F3660305's 70 = 6pt, 412BC89E's Boundary 120 = 12pt.
      expect(builder.font_size_from(fontsz: "70")).to eq(6)
      expect(builder.font_size_from(fontsz: "80")).to eq(7)
      expect(builder.font_size_from(fontsz: "90")).to eq(9)
      expect(builder.font_size_from(fontsz: "100")).to eq(9)
      expect(builder.font_size_from(fontsz: "105")).to eq(10)
      expect(builder.font_size_from(fontsz: "120")).to eq(12)
      expect(builder.font_size_from(fontsz: "140")).to eq(13)
    end

    it "treats fontsz 0 as use-default" do
      expect(builder.font_size_from(fontsz: "0")).to be_nil
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

    it "docks each connector's endpoints on element perimeters" do
      # EA redraws stored connectors between the closest FACING edges
      # when the stored port route does not already dock them, so the
      # waypoints are no longer the raw ports — but every endpoint
      # terminates on an element perimeter (corpus: 417 identity-
      # paired connectors on EA-published references).
      checked = 0
      document.diagrams.each do |diagram|
        rects = (diagram.elements || []).filter_map do |e|
          b = e.bounds || e.image_bounds
          b && [b.x, b.y, b.width, b.height]
        end
        next if rects.empty?

        (diagram.connectors || []).each do |connector|
          next unless connector.source_port || connector.target_port

          waypoints = connector.waypoints.map(&:position)
          expect(waypoints.size).to be >= 2
          [waypoints.first, waypoints.last].each do |pt|
            on_box = rects.any? do |x, y, w, h|
              (((pt.x - x).abs <= 2 || (pt.x - (x + w)).abs <= 2) &&
                pt.y.between?(y - 2, y + h + 2)) ||
                (((pt.y - y).abs <= 2 || (pt.y - (y + h)).abs <= 2) &&
                  pt.x.between?(x - 2, x + w + 2))
            end
            expect(on_box).to be(true)
          end
          checked += 1
        end
      end
      expect(checked).to be > 10
    end
  end
end
