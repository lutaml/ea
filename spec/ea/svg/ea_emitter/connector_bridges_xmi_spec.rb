# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Connectors, "plateau XMI crossings" do
  include QeaBridgeCorpusHelpers

  before { skip "plateau XMI unavailable" unless File.exist?(plateau_xmi_path) }

  it "ranks diagram 110 connectors by exported child order" do
    _document, diagram = plateau_xmi_diagram("{B62C02B3-69DB-49e9-8089-4EE398BDE666}")
    rank = ->(guid) { xmi_rank(diagram, guid) }
    carrier95 = rank.call("{97DD0658-254B-46b8-86F2-92CA5FFAE8AC}")
    carrier94 = rank.call("{D6830A4A-F338-4c66-9B8D-9076B49EFC80}")

    expect(carrier95.size).to eq(1)
    expect(carrier95.first).to be > rank.call("{92072D54-33C7-40e8-84F7-F28A6BCCC96B}").first
    expect(carrier94.first).to be > rank.call("{92072D54-33C7-40e8-84F7-F28A6BCCC96B}").first
    expect(carrier94.first).to be > rank.call("{35192687-3A64-4b1c-A68E-C5B1D1BB7E8A}").first
  end

  it "bridges only the vertical carriers on diagram 110" do
    paths = xmi_arc_paths("{B62C02B3-69DB-49e9-8089-4EE398BDE666}")

    expect(paths.size).to eq(2)
    expect(paths).to all(match(/\AM (\d+) -?\d+ L \1 /))
  end

  it "keeps the diagram 148 crossings unchanged" do
    expect(xmi_arc_paths("{00C5C772-5A03-434f-BF30-AC37542A1AAC}").sum { |d| d.scan(" A ").size }).to eq(10)
  end
end
