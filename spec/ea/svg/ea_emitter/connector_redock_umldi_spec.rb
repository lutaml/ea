# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::ConnectorRedock, "UMLDI route authority" do
  include ConnectorRedockHelpers

  it "preserves the exported route and seats its marker at the exported target" do
    fixture = redock_fixture(points: [[10, 100], [10, 40]], style: { umldi_route: true })

    expect(redock_output(fixture)).to eq(
      [["M 10 100 L 10 40"], ["10 40 16 56 4 56"]]
    )
  end

  it "preserves exported endpoints that coincide with compartment dividers" do
    fixture = redock_fixture(source: [0, 100, 40, 40], target: [200, 0, 40, 40],
                             points: [[40, 120], [200, 20]],
                             dividers: { "s" => 120, "t" => 20 }, style: { umldi_route: true })

    expect(redock_output(fixture).first).to eq(["M 40 120 L 200 20"])
  end

  it "keeps ordinary computed routes eligible for drawn-outline redocking" do
    fixture = redock_fixture(points: [[10, 100], [10, 40]])

    expect(redock_output(fixture)).to eq(
      [["M 20 99 L 20 41"], ["20 41 26 57 14 57"]]
    )
  end
end
