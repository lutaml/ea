# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Xmi::LiquidDrops::DataTypeDrop do # rubocop:disable Metrics/BlockLength
  let(:root) { Struct.new(:model).new(Struct.new(:name).new("Root")) }
  let(:lookup) do
    Class.new do
      def find_upper_level_packaged_element(_id) = nil
    end.new
  end
  let(:model) { Struct.new(:xmi_id, :name).new("EAID_DT1", "Measure") }
  let(:options) { { lookup: lookup, xmi_root_model: root } }

  it "constructs without guidance" do
    expect { described_class.new(model, nil, options) }.not_to raise_error
  end

  it "has no guidance when none is supplied" do
    drop = described_class.new(model, nil, options)

    expect(drop.has_guidance?).to be false
  end

  it "matches guidance by name" do
    guidance = {
      "data_types" => [{ "name" => "Measure", "guidance" => "A quantity." }]
    }
    drop = described_class.new(model, guidance, options)

    expect(drop.has_guidance?).to be true
  end

  it "has no guidance when the data type is absent from the guidance list" do
    guidance = {
      "data_types" => [{ "name" => "Other", "guidance" => "Unrelated." }]
    }
    drop = described_class.new(model, guidance, options)

    expect(drop.has_guidance?).to be false
  end

  it "tolerates guidance without a data_types key" do
    drop = described_class.new(model, { "classes" => [] }, options)

    expect(drop.has_guidance?).to be false
  end
end
