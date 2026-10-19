# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA phantom Property labels through the public adapter" do
  include TestDatabaseHelper
  include QeaEndLabelHelpers
  include QeaPhantomLabelHelpers

  let(:native_positions) { JSON.parse(File.read(fixtures_path("svg/phantom_property_positions.json"))) }

  it "places source clusters without a diagram-link row using the directional Property seat", :aggregate_failures do
    native_positions.each do |name, _anchor, heading, *native|
      upward = heading[0].zero?
      result = qea_phantom_labels(name, upward: upward)
      role, stereotype = result[:texts].select { |text| ["+#{name}", "«property»"].include?(text[:text]) }
      anchor_x, anchor_y = result[:first]
      width = Ea::Fonts::Metrics.text_length("+#{name}", 7, family: "Cambria")
      baseline = upward ? -6 : -7

      expect([role[:x], role[:y]]).to eq([anchor_x - 60 - width, anchor_y + baseline])
      expect([stereotype[:x], stereotype[:y]]).to eq([role[:x] + native[1][0] - native[0][0], role[:y] + 12])
      expect(result[:mult]).to eq(upward ? [anchor_x + 3, anchor_y - 6] : [anchor_x - 19, anchor_y + 15])
      expect(result[:texts].map { |text| text[:text] }).to include("+#{name}", "«property»", "0..1")
    end
  end
end
