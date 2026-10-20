# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "UMLDI target role bounds beside a stored LRT box" do
  let(:helpers) { UmldiTargetBoundsPrecedenceHelpers }
  let(:document) { helpers.adapt }

  it "stores LRT boxes for both 88D0CB44 target roles" do
    expect([helpers::EXTERNAL, helpers::XAL].map { |id| helpers.connector(document, id).label_boxes.key?(:lrt) })
      .to eq([true, true])
  end

  it "seats the roles at the adapter-built UMLDI bounds" do
    expect(helpers.role_positions(document)).to eq(
      "+externalReference" => [797.0, 302.0], "+xalAddress" => [925.0, 190.0]
    )
  end

  it "keeps the connector paths of the adapter-built bounds" do
    without = helpers.route_paths(helpers.with_bounds(helpers.adapt))

    expect(helpers.route_paths(document)).to eq(without)
  end
end

RSpec.describe "UMLDI target role bounds supplied beside a stored LRT box" do
  let(:helpers) { UmldiTargetBoundsPrecedenceHelpers }
  let(:document) { helpers.adapt }

  it "seats the roles at their source-owned UMLDI bounds when supplied" do
    helpers.with_bounds(document, external: helpers::EXTERNAL_BOX, xal: helpers::XAL_BOX)

    expect(helpers.role_positions(document)).to eq(
      "+externalReference" => [797.0, 302.0], "+xalAddress" => [925.0, 190.0]
    )
  end

  it "keeps the connector paths when the bounds are supplied" do
    before = helpers.route_paths(helpers.with_bounds(helpers.adapt))
    helpers.with_bounds(document, external: helpers::EXTERNAL_BOX, xal: helpers::XAL_BOX)

    expect(helpers.route_paths(document)).to eq(before)
  end

  it "keeps the LRT seat when no UMLDI bounds are supplied" do
    helpers.with_bounds(document)

    expect(helpers.role_positions(document)).to eq(
      "+externalReference" => [885.0, 311.0], "+xalAddress" => [922.0, 199.0]
    )
  end
end
