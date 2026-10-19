# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers
  include Mode3FlushOverlapCases

  let(:base) do
    { path: "", connector_type: "Association", style: "Mode=3;LWidth=0;",
      geometry: "SX=-6;SY=-2;EX=-57;EY=-2;EDGE=2;",
      source: [100, 100, 134, 70], target: [420, 100, 134, 70] }
  end

  it "docks empty flush routes and label origins on the native shared row" do
    Mode3FlushOverlapCases::NATIVE_CASES.each do |source, target, row, expected|
      result = render_qea_route(**base, source: source, target: target) do |document|
        expect(flush_overlap_points(document)).to eq([[source[0] + source[2], row], [target[0], row]])
      end
      expect(result[:paths].first).to eq(expected)
    end
  end

  it "preserves authored routes, custom widths and other overlap families" do
    Mode3FlushOverlapCases::CONTROLS.each do |overrides, expected|
      expect(render_qea_route(**base, **overrides)[:paths].first).to eq(expected), overrides.inspect
    end
  end
end
