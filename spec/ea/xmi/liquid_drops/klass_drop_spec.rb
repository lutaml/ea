# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Xmi::LiquidDrops::KlassDrop do
  it "constructs with a nil model even when an xmi root is supplied" do
    # Template rendering builds drops for guidance-only lookups where
    # the model may be absent; construction must not walk dependencies
    # off nil.
    root = Struct.new(:model).new("root-model")
    expect { described_class.new(nil, nil, xmi_root_model: root) }
      .not_to raise_error
  end

  it "walks dependencies when both model and xmi root are present" do
    model = Struct.new(:xmi_id, :name).new("EAID_C1", "C")
    lookup = Class.new do
      def select_dependencies_by_supplier(_id) = [:dep]
      def select_dependencies_by_client(_id) = []
      def find_matched_element(_id) = nil
    end.new
    root = Struct.new(:model).new("root-model")

    expect { described_class.new(model, nil, xmi_root_model: root, lookup: lookup) }
      .not_to raise_error
  end
end
