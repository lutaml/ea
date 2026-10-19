# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Diagram element font size provenance" do
  it "keeps unspecified provenance distinct from source inheritance through JSON" do
    [nil, false, true].each do |inherited|
      element = Ea::Model::DiagramElement.new(font_size_inherited: inherited)
      round_trip = Ea::Model::DiagramElement.from_json(element.to_json)

      expect(round_trip.font_size_inherited).to eq(inherited)
    end
  end
end
