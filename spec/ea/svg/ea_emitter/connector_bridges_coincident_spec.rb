# frozen_string_literal: true

require "spec_helper"

module CoincidentBridgeHelpers
  include ConnectorBridgesHelpers

  def carrier_path(carrier_points, partners)
    carrier = bridge_connector("carrier", carrier_points, paint_order: [30])
    lower = partners.each_with_index.map do |points, index|
      bridge_connector("p#{index}", points, paint_order: [index + 1])
    end
    bridge_paths(bridge_diagram([carrier, *lower])).first
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "near-coincident and coincident crossings" do
  include CoincidentBridgeHelpers

  it "draws one long arc over horizontals one pixel apart (30D62231)" do
    horizontals = [352, 353, 354].map { |y| [[664, y], [1120, y]] }
    expect(carrier_path([[758, 389], [758, 317]], horizontals))
      .to eq("M 758 389 L 758 360 A 6 7 180 0 0 758 346 L 758 317")
  end

  it "draws one long arc for a horizontal carrier over near-coincident verticals" do
    verticals = [100, 101].map { |x| [[x, 0], [x, 100]] }
    expect(carrier_path([[0, 50], [200, 50]], verticals))
      .to eq("M 0 50 L 94 50 A 6.5 6 180 0 0 107 50 L 200 50")
  end

  it "keeps the normal arc for a single crossing" do
    expect(carrier_path([[758, 389], [758, 317]], [[[664, 353], [1120, 353]]]))
      .to eq("M 758 389 L 758 359 A 6 6 180 0 0 758 347 L 758 317")
  end

  it "still suppresses crossings that overlap but are not near-coincident" do
    horizontals = [350, 356].map { |y| [[664, y], [1120, y]] }
    expect(carrier_path([[758, 389], [758, 317]], horizontals)).to eq("M 758 389 L 758 317")
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "coincident crossings on slanted and aligned carriers" do
  include CoincidentBridgeHelpers

  it "adds one zero-length arc for three verticals meeting a slanted carrier at one point (0BE81AC5)" do
    verticals = [10, 20, 30].map { |top| [[50, 100], [50, top]] }
    expect(carrier_path([[0, 0], [100, 100]], verticals))
      .to eq("M 0 0 L 44 44 A 6 6 180 0 0 56 56 L 56 56 A 6 6 0 1 0 56 56 L 100 100")
  end

  it "draws a single plain arc for two coincident verticals on a slanted carrier" do
    verticals = [[[50, 0], [50, 100]], [[50, 10], [50, 90]]]
    expect(carrier_path([[0, 0], [100, 100]], verticals)).to eq("M 0 0 L 44 44 A 6 6 180 0 0 56 56 L 100 100")
  end

  it "draws a single plain arc for three coincident verticals on a horizontal carrier" do
    verticals = [[[50, 0], [50, 100]], [[50, 10], [50, 90]], [[50, 20], [50, 80]]]
    expect(carrier_path([[0, 50], [100, 50]], verticals)).to eq("M 0 50 L 44 50 A 6 6 180 0 0 56 50 L 100 50")
  end
end
