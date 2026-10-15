# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:base) do
    { path: "", connector_type: "Association", style: "Mode=2;LWidth=2;",
      geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=4;",
      source: [650, 230, 181, 80], target: [292, 220, 229, 125] }
  end

  describe "Mode 2 Association overlap rays" do
    it "docks a straight line through the middle of the facing boxes' overlap" do
      cases = [
        [{}, "M 392 90 L 265 90"],
        # overlap 240..291: the middle 265.5 floors to 265
        [{ source: [972, 211, 189, 80], target: [721, 240, 120, 60] }, "M 285 94 L 156 94"],
        # shared SY = EY = 10 moves a horizontal ray up from the 468.5 middle
        [{ geometry: "SX=2;SY=10;EX=2;EY=10;EDGE=4;", style: "Mode=2;LWidth=0;",
           source: [1172, 413, 120, 80], target: [815, 444, 235, 156] }, "M 391 85 L 271 85"],
        # shared SX = EX = 7 moves a vertical ray right from the 513 middle
        [{ geometry: "SX=7;SY=0;EX=7;EY=0;EDGE=1;",
           source: [463, 528, 100, 77], target: [453, 394, 136, 77] }, "M 102 173 L 102 118"]
      ]
      cases.each do |overrides, expected|
        expect(render_qea_route(**base, **overrides)[:paths].first).to eq(expected), overrides.inspect
      end
    end

    it "keeps legacy docking for naturally aligned centres without the producer marker" do
      aligned = { geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=2;", target: [292, 230, 229, 80] }

      expect(render_qea_route(**base, **aligned)[:paths].first).to eq("M 393 80 L 264 80")
    end

    it "keeps the stored route when the offsets differ, the boxes miss, or the route is not Mode 2" do
      controls = [
        [{ geometry: "SX=8;SY=-4;EX=15;EY=-33;EDGE=4;",
           source: [644, 154, 181, 80], target: [270, 150, 200, 150] }, "M 409 80 L 235 81"],
        [{ target: [292, 400, 229, 125] }, "M 413 120 L 256 210"],
        [{ style: "Mode=3;LWidth=2;" }, "M 393 93 L 264 97"],
        [{ path: "600:-300;" }, "M 393 93 L 264 97"]
      ]
      controls.each do |overrides, expected|
        expect(render_qea_route(**base, **overrides)[:paths].first).to eq(expected), overrides.inspect
      end
    end
    it "keeps an offset outside the shared span on its original side docks" do
      result = render_qea_route(
        path: "", connector_type: "Association", style: "Mode=2;LWidth=2;",
        geometry: "SX=300;SY=0;EX=300;EY=0;EDGE=1;",
        source: [463, 528, 100, 77], target: [453, 394, 136, 77]
      )

      expect(result[:paths]).to eq(["M 395 212 L 403 78", "M 408.1 93.33 L 403 78 L 396.12 92.62"])
    end
  end
end
