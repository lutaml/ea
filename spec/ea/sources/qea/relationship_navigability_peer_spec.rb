# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Sources::Qea::RelationshipBuilder, "stored endpoint navigability" do
  let(:database) { Ea::Qea::Database.new(nil) }
  let(:builder) { described_class.new(database) }

  %w[Association Aggregation Composition].each do |type|
    [[0, 1], [1, 0], [0, 0]].each do |source, target|
      it "imports #{type} endpoint flags #{source}/#{target} independently of direction" do
        row = Ea::Qea::Models::EaConnector.new(
          connector_type: type, direction: "Source -> Destination",
          sourceisnavigable: source, destisnavigable: target
        )

        relationship = builder.build_one(row)

        expect(relationship.source_navigable).to eq(source == 1)
        expect(relationship.target_navigable).to eq(target == 1)
      end
    end
  end
end

RSpec.describe Ea::Sources::Qea::RelationshipBuilder, "unspecified endpoint navigability" do
  let(:builder) { described_class.new(Ea::Qea::Database.new(nil)) }

  [["->", false, true], ["<-", true, false], ["", true, true],
   ["Source -> Destination", true, true]].each do |direction, source_expected, target_expected|
    it "preserves the direction fallback when flags are absent for #{direction.inspect}" do
      row = Ea::Qea::Models::EaConnector.new(connector_type: "Association", direction: direction)

      relationship = builder.build_one(row)

      expect(relationship.source_navigable).to eq(source_expected)
      expect(relationship.target_navigable).to eq(target_expected)
    end
  end

  it "preserves the direction fallback for unspecified flags" do
    row = Ea::Qea::Models::EaConnector.new(
      connector_type: "Association", direction: "<-",
      sourceisnavigable: 255, destisnavigable: 255
    )

    relationship = builder.build_one(row)

    expect(relationship.source_navigable).to be(true)
    expect(relationship.target_navigable).to be(false)
  end
end
