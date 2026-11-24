# frozen_string_literal: true

require "spec_helper"

RSpec.describe "EA bare * multiplicity" do
  it "parses as unbounded 0..* on the association member end" do
    doc = Ea.to_uml(fixtures_path("association_multiplicity_star.xmi"))

    cardinalities = doc.associations.filter_map(&:member_end_cardinality)
    expect(cardinalities).to include(
      have_attributes(min: "0", max: "*")
    )
  end
end
