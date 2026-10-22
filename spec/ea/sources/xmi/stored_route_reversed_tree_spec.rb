# frozen_string_literal: true

require "spec_helper"

# Slices from 20251010_current_plateau_v5.1.xmi diagram 5038EEE3 and 30D62231.
RSpec.describe Ea::Sources::Xmi::StoredRoute, "reversed vertical trees" do
  include XmiRouteSliceHelpers

  let(:tree_style) { { mode: "3", lwidth: "0", tree: "V", reversed_ends: true } }
  let(:lower) { [800, 720, 153, 80] }
  let(:upper) { [630, 260, 268, 258] }

  it "routes a reversed vertical tree through the bus 50px past the End box" do
    metadata = route(tree_style, "Mode=3;EOID=CC91A3FC;SOID=E9A8AB7A;LWidth=0;TREE=V;", "904:-670;764:-670;",
                     [lower, upper], [[41, -125], [0, 0]], 3)
    expect(vertices(metadata)).to eq([[904, 720], [904, 568], [764, 568], [764, 518]])
    expect(metadata[:style]).not_to include(:reversed_ends)
  end

  it "keeps the authored route when the ends are not reversed" do
    expect(route(tree_style.except(:reversed_ends), "Mode=3;LWidth=0;TREE=V;", "904:-670;764:-670;",
                 [lower, upper], [[41, -125], [0, 0]], 3)).to eq({})
  end

  it "seats source labels left when the leg starts beside its box" do
    metadata = route(tree_style, "Mode=3;EOID=CC91A3FC;SOID=E9A8AB7A;LWidth=0;TREE=V;", "962:-670;764:-670;",
                     [lower, upper], [[86, -4], [0, 0]], 3)
    expect(metadata[:style]).to include(left_seated_source: true)
  end

  it "keeps a stored bus that is not the one EA discards" do
    expect(route(tree_style, "Mode=3;EOID=CC91A3FC;SOID=E9A8AB7A;LWidth=0;TREE=V;", "904:-600;764:-600;",
                 [lower, upper], [[41, -125], [0, 0]], 3)).to eq({})
  end

  it "yields when an out-of-box offset would detach the leg" do
    expect(route(tree_style, "Mode=3;EOID=CC91A3FC;SOID=E9A8AB7A;LWidth=0;TREE=V;", "904:-670;764:-670;",
                 [lower, upper], [[500, -10], [0, 0]], 3)).to eq({})
  end

  it "drops the repeated vertex of a straight reversed tree" do
    metadata = route(tree_style, "Mode=3;EOID=CC91A3FC;SOID=E9A8AB7A;LWidth=0;TREE=V;", "746:-670;746:-670;",
                     [[610, 720, 153, 80], upper], [[60, 0], [-18, 0]], 3)
    expect(vertices(metadata)).to eq([[746, 720], [746, 568], [746, 518]])
  end

  it "seats the source labels of a reversed lateral tree left" do
    metadata = route(tree_style.merge(tree: "LV"), "Mode=3;LWidth=0;TREE=LV;", "764:-760;",
                     [[610, 720, 153, 80], upper], [[0, 0], [0, 0]], 3)
    expect(metadata[:style]).to include(left_seated_source: true)
  end
end

RSpec.describe Ea::Sources::Xmi::StoredRoute, "reversed corners and elbows" do
  include XmiRouteSliceHelpers

  it "clips a reversed single-corner Association from each stored origin" do
    metadata = route({ mode: "3", lwidth: "0", reversed_ends: true }, "Mode=3;EOID=11117DB7;SOID=2DD4FF8E;LWidth=0;",
                     "460:-343;", [[410, 720, 100, 80], [100, 260, 250, 270]], [[0, 52], [0, 0]], 2)
    expect(vertices(metadata)).to eq([[460, 708], [460, 343], [350, 367]])
  end

  it "gives a Mode 2 EDGE 4 Association with no Path QEA's elbow ports despite a UMLDI route (934F4502)" do
    metadata = route({ umldi_route: true, mode: "2", lwidth: "2" }, "Mode=2;EOID=3A74ACC6;SOID=1145CB70;LWidth=2;", "",
                     [[601, 300, 100, 97], [263, 370, 202, 110]], [[-51, 20], [-102, 20]], 4)
    expect(vertices(metadata)).to eq([[600, 328], [262, 405]])
    expect(metadata[:style]).to include(auto_port_elbow: true)
  end
end
