# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Classifier attribute content sizing" do
  include ClassifierContentSizingHelpers

  it "fits the rendered inset for custom themes, point sizes and compact fonts", :aggregate_failures do
    [{}, { inset: 31 }, { size: 7, family: "Cambria" }, { size: 7 }, { unit: "px" }].each do |options|
      stored, drawn, row = classifier_content_sizing_render(**options)

      expect(drawn.width).to eq(row["x"].to_f - drawn.x + row["textLength"].to_i + 5), options.inspect
      expect(stored.width).to eq(40)
    end
  end

  it "preserves saved boxes that already contain their rows" do
    stored, drawn, = classifier_content_sizing_render(width: 400, height: 180, size: 7, family: "Cambria")

    expect([drawn.width, drawn.height]).to eq([400, 180])
    expect([stored.width, stored.height]).to eq([400, 180])
  end

  it "keeps eight units of trailing space outside compact Cambria point fonts", :aggregate_failures do
    [{}, { family: "Cambria", size: 9 }, { family: "Cambria", size: 7, unit: "px" }].each do |options|
      stored, drawn, row = classifier_content_sizing_render(**options)

      expect(drawn.y + drawn.height - row["y"].to_f).to eq(8), options.inspect
      expect(stored.height).to eq(20)
    end
  end
end
