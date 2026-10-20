# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA grown classifier ray origins" do
  include QeaRoutingHelpers
  include QeaGrownRayHelpers

  let(:empty_ray) do
    { source: [260, 490, 224, 70], target: [331, 370, 100, 80],
      drawn_source: [260, 490, 235, 80], geometry: "SX=24;SY=-8;EX=15;EY=-8;EDGE=1;",
      style: "Mode=3;LWidth=2;" }
  end

  it "keeps saved offsets relative to the grown classifier center for an empty route" do
    expect(grown_ray_pairs(**empty_ray)).to eq([[398, 489], [397, 451]])
  end

  it "uses the grown center for a direct route with a stale stored jog" do
    expect(grown_ray_pairs(source: [650, 350, 221, 71], target: [691, 260, 100, 49],
                           drawn_source: [650, 350, 235, 80],
                           geometry: "SX=-10;SY=1;EX=10;EY=-25;EDGE=1;",
                           style: "Mode=1;LWidth=2;", path: "840:-359;730:-359;"))
      .to eq([[754, 349], [751, 310]])
  end

  it "preserves saved centers when classifier bounds do not grow" do
    expect(grown_ray_pairs(**empty_ray.merge(drawn_source: empty_ray[:source])))
      .to eq([[396, 489], [396, 451]])
  end

  it "preserves authored bends instead of replacing them with a grown-center ray" do
    expect(grown_ray_pairs(**empty_ray.merge(path: "500:-480;550:-460;"))).to be_nil
  end
end
