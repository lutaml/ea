# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Connectors, "plateau QEA crossings" do
  include QeaBridgeCorpusHelpers

  before { skip "plateau QEA unavailable" unless File.exist?(plateau_path) }

  it "orders diagram 110 crossings by start placement then connector id" do
    _document, diagram = plateau_diagram("{B62C02B3-69DB-49e9-8089-4EE398BDE666}")
    key = ->(id) { connector_by_id(diagram, id).paint_order }

    expect(key.call(95) <=> key.call(130)).to eq(1)
    expect(key.call(94) <=> key.call(130)).to eq(1)
    expect(key.call(94) <=> key.call(129)).to eq(1)
  end

  it "bridges 95 and 94 over 130 and 129 on diagram 110" do
    expect(rendered_arc_seats("{B62C02B3-69DB-49e9-8089-4EE398BDE666}")).to eq(
      [[265, 404], [395, 404], [395, 474]]
    )
  end

  it "keeps the diagram 147 crossings unchanged" do
    seats = rendered_arc_seats("{E7AABA98-2450-4986-9736-DCCAF0108C50}")
    expect([seats.size, seats.first(3)]).to eq([13, [[214, 526], [388, 860], [388, 955]]])
  end

  it "keeps the diagram 148 crossings unchanged" do
    expect(rendered_arc_seats("{00C5C772-5A03-434f-BF30-AC37542A1AAC}")).to eq(
      [[179, 608], [185, 479], [221, 491], [221, 614], [582, 519], [725, 1017],
       [725, 1035], [754, 1017], [754, 1035], [850, 259], [850, 283], [850, 305]]
    )
  end
end
