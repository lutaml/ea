# frozen_string_literal: true

require "spec_helper"

# Plateau diagram 5038EEE3: five vertical-tree Associations store SOID/EOID in
# the reverse of their Start/End objects and a Path (bus 50px above the
# MultiSolid/MultiSurface boxes) that EA no longer draws. EA routes them from
# the Start box to the End box with the bus 50px past the End box's facing edge.
# rubocop:disable Metrics/BlockLength
RSpec.describe "QEA width-0 vertical tree Associations with reversed SOID/EOID" do
  include QeaRoutingHelpers

  # Expected paths are in the frameless canvas: stored x - 595, y - 220
  # (x - 575 when the MultiSurface box at x=610 sets the left edge).
  let(:multi_solid) { [800, 720, 153, 80] }
  let(:plant_cover) { [630, 260, 268, 258] }

  def render_reversed(geometry:, path:, source: multi_solid)
    render_qea_route(connector_type: "Association", source: source, target: plant_cover,
                     object_styles: ["DUID=MSMS;", "DUID=PCPC;"],
                     style: "Mode=3;EOID=MSMS;SOID=PCPC;Color=-1;LWidth=0;TREE=V;",
                     geometry: geometry, path: path)
  end

  it "routes from the Start leg to a bus 50px past the End box (connector 212)" do
    # The saved origin lies right of the box, level with it: kept literally.
    result = render_reversed(geometry: "SX=86;SY=-4;EX=0;EY=0;EDGE=3;", path: "850:-670;876:-670;")

    # Stored M 962 764 L 962 568 L 764 568 L 764 518

    expect(result[:paths].first).to eq("M 367 544 L 367 348 L 169 348 L 169 298")
  end

  it "docks the Start leg on the facing edge when the origin is over the box (connector 208)" do
    result = render_reversed(source: [610, 720, 153, 80], geometry: "SX=-59;SY=4;EX=0;EY=0;EDGE=3;",
                             path: "704:-670;686:-670;")

    # Stored M 627 720 L 627 568 L 764 568 L 764 518

    expect(result[:paths].first).to eq("M 52 500 L 52 348 L 189 348 L 189 298")
  end

  it "pulls a far-offset Start leg toward the box centre (connector 211, fit)" do
    result = render_reversed(geometry: "SX=41;SY=-125;EX=0;EY=0;EDGE=3;", path: "805:-670;876:-670;")

    # Native M 904 650 (unpulled centre + SX would be 917)

    expect(result[:paths].first).to eq("M 309 500 L 309 348 L 169 348 L 169 298")
  end

  it "pulls a slightly offset Start leg by two pixels (connector 902, fit)" do
    result = render_reversed(geometry: "SX=64;SY=-13;EX=0;EY=0;EDGE=3;", path: "828:-670;876:-670;")

    # Native M 938 650 (unpulled would be 940)

    expect(result[:paths].first).to eq("M 343 500 L 343 348 L 169 348 L 169 298")
  end

  it "keeps the stored bus when SOID and EOID follow Start and End" do
    result = render_qea_route(connector_type: "Association", source: plant_cover, target: multi_solid,
                              object_styles: ["DUID=PCPC;", "DUID=MSMS;"],
                              style: "Mode=3;SOID=PCPC;EOID=MSMS;LWidth=0;TREE=V;",
                              geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=3;", path: "764:-670;876:-670;")

    # Stored bus y 670 kept

    expect(result[:paths].first).to eq("M 169 298 L 169 450 L 281 450 L 281 500")
  end

  it "leaves a reversed link without two level bends on its existing route" do
    result = render_reversed(geometry: "SX=86;SY=-4;EX=0;EY=0;EDGE=3;", path: "850:-670;876:-660;")

    # Facing-edge diagonal, as before this route

    expect(result[:paths].first).to eq("M 358 519 L 238 298")
  end
end
# rubocop:enable Metrics/BlockLength
