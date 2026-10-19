# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA aggregate diamond fill and presence" do
  include QeaMarkerHelpers

  {
    "shared aggregation" => ["Aggregation", { destisaggregate: 1 }, :diamond_hollow],
    "composite aggregation" => ["Aggregation", { destisaggregate: 2 }, :diamond_filled],
    "composition" => ["Composition", { destisaggregate: 2 }, :diamond_filled],
    "association with a shared target end" => ["Association", { destisaggregate: 1 }, :diamond_hollow],
    "association with a composite source end" => ["Association", { sourceisaggregate: 2 }, :diamond_filled]
  }.each do |label, (type, flags, style_key)|
    it "draws the #{label} diamond as #{style_key}" do
      layers = diamond_layers(connector_type: type, **flags)

      expect(layers.map(&:style_key)).to include(style_key)
      expect(layers.map(&:style_key) & %i[diamond_filled diamond_hollow]).to eq([style_key])
    end
  end

  it "keeps a plain association free of diamonds" do
    layers = diamond_layers(connector_type: "Association")

    expect(layers.map(&:style_key) & %i[diamond_filled diamond_hollow]).to be_empty
  end

  it "fills the hollow diamond white and the solid diamond black" do
    shared = diamond_layers(connector_type: "Aggregation", destisaggregate: 1)
    composite = diamond_layers(connector_type: "Aggregation", destisaggregate: 2)

    expect(shared.find { |l| l.style_key == :diamond_hollow }.style).to include("fill:#FFFFFF")
    expect(composite.find { |l| l.style_key == :diamond_filled }.style).to include("fill:#000000")
  end

  it "keeps the navigability arrow next to the association diamond" do
    layers = diamond_layers(connector_type: "Association", destisaggregate: 1,
                            direction: "Source -> Destination")

    expect(layers.map(&:style_key)).to contain_exactly(:diamond_hollow, :connector_line)
  end

  describe "explicit endpoint flags" do
    it "lets a shared dest flag override the Composition type default" do
      layers = diamond_layers(connector_type: "Composition", destisaggregate: 1)

      expect(layers.map(&:style_key)).to include(:diamond_hollow)
      expect(layers.map(&:style_key)).not_to include(:diamond_filled)
    end

    it "puts a source-flagged diamond at the source end, hollow and arrowless" do
      geometry = diamond_geometry(connector_type: "Aggregation", sourceisaggregate: 1)

      expect(geometry[:tip]).to eq(geometry[:start])
      expect(geometry[:arrows]).to eq(0)
      expect(geometry[:keys]).to eq(["#FFFFFF"])
    end

    it "puts a dest-flagged diamond at the target end" do
      geometry = diamond_geometry(connector_type: "Aggregation", destisaggregate: 1)

      expect(geometry[:tip]).to eq(geometry[:finish])
    end

    it "keeps a composite source flag solid at the source end" do
      geometry = diamond_geometry(connector_type: "Aggregation", sourceisaggregate: 2)

      expect([geometry[:tip], geometry[:keys]]).to eq([geometry[:start], ["#000000"]])
    end
  end
end
