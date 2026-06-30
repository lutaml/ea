# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Qea::Models::EaObject do
  describe "#transformer_type" do
    it "returns :enumeration for Enumeration object_type" do
      obj = described_class.new(object_type: "Enumeration")
      expect(obj.transformer_type).to eq(:enumeration)
    end

    it "returns :enumeration for Class with enumeration stereotype" do
      obj = described_class.new(object_type: "Class", stereotype: "enumeration")
      expect(obj.transformer_type).to eq(:enumeration)
    end

    it "returns :enumeration for Class with uppercase stereotype" do
      obj = described_class.new(object_type: "Class", stereotype: "Enumeration")
      expect(obj.transformer_type).to eq(:enumeration)
    end

    it "returns :data_type for DataType object_type" do
      obj = described_class.new(object_type: "DataType")
      expect(obj.transformer_type).to eq(:data_type)
    end

    it "returns :class for Class object_type" do
      obj = described_class.new(object_type: "Class")
      expect(obj.transformer_type).to eq(:class)
    end

    it "returns :class for Interface object_type" do
      obj = described_class.new(object_type: "Interface")
      expect(obj.transformer_type).to eq(:class)
    end

    it "returns nil for Text object_type (diagram annotation, not a model element)" do
      obj = described_class.new(object_type: "Text")
      expect(obj.transformer_type).to be_nil
    end

    it "returns nil for ProxyConnector object_type (EA-internal plumbing)" do
      obj = described_class.new(object_type: "ProxyConnector")
      expect(obj.transformer_type).to be_nil
    end

    it "returns nil for Note object_type (diagram annotation, not a model element)" do
      obj = described_class.new(object_type: "Note")
      expect(obj.transformer_type).to be_nil
    end

    it "returns :instance for Object object_type" do
      obj = described_class.new(object_type: "Object")
      expect(obj.transformer_type).to eq(:instance)
    end

    it "returns nil for Package object_type" do
      obj = described_class.new(object_type: "Package")
      expect(obj.transformer_type).to be_nil
    end

    it "returns nil for unknown object_type" do
      obj = described_class.new(object_type: "Unknown")
      expect(obj.transformer_type).to be_nil
    end
  end

  describe "#stereotype_is?" do
    it "returns true when stereotype matches case-insensitively" do
      obj = described_class.new(stereotype: "Enumeration")
      expect(obj.stereotype_is?("enumeration")).to be true
    end

    it "returns false when stereotype does not match" do
      obj = described_class.new(stereotype: "entity")
      expect(obj.stereotype_is?("enumeration")).to be false
    end

    it "returns false when stereotype is nil" do
      obj = described_class.new
      expect(obj.stereotype_is?("enumeration")).to be false
    end
  end
end
