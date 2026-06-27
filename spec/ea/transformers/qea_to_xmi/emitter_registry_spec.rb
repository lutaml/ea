# frozen_string_literal: true

require "spec_helper"
require "ea/transformers/qea_to_xmi"

# Minimal stand-in for an emitter — used in place of doubles (forbidden by
# project rules). A Struct satisfies the [#emit] contract just fine.
TestEmitter = Struct.new(:name) do
  def emit(_record, _ctx)
    name
  end
end

RSpec.describe Ea::Transformers::QeaToXmi::EmitterRegistry do
  after do
    described_class.delete(:test_kind)
    described_class.delete(:another_kind)
    described_class.delete(:extension_kind)
    described_class.delete(:present)
  end

  describe ".register / .for" do
    it "stores an emitter by symbolic key and returns it via .for" do
      emitter = TestEmitter.new("test")
      described_class.register(:test_kind, emitter)
      expect(described_class.for(:test_kind)).to be(emitter)
    end

    it "raises ArgumentError when no emitter is registered for a key" do
      expect { described_class.for(:no_such_kind) }
        .to raise_error(ArgumentError, /No emitter registered for :no_such_kind/)
    end

    it "calls #emit on the registered emitter" do
      described_class.register(:test_kind, TestEmitter.new("fired"))
      result = described_class.for(:test_kind).emit(nil, nil)
      expect(result).to eq("fired")
    end
  end

  describe ".for?" do
    it "returns the registered emitter (truthy) when present" do
      emitter = TestEmitter.new("present")
      described_class.register(:present, emitter)
      expect(described_class.for?(:present)).to be(emitter)
    end

    it "returns nil (falsy) when no emitter is registered" do
      expect(described_class.for?(:absent_kind)).to be_nil
    end
  end

  describe ".registered_keys" do
    it "lists all registered keys" do
      described_class.register(:test_kind, TestEmitter.new("a"))
      described_class.register(:another_kind, TestEmitter.new("b"))
      expect(described_class.registered_keys)
        .to include(:test_kind, :another_kind)
    end
  end

  describe ".delete" do
    it "removes a registered key" do
      described_class.register(:test_kind, TestEmitter.new("x"))
      described_class.delete(:test_kind)
      expect(described_class.for?(:test_kind)).to be_nil
    end
  end

  describe "OCP — extension without modification" do
    it "lets new kinds register without changing registry internals" do
      described_class.register(:extension_kind, TestEmitter.new("ext"))
      expect(described_class.for?(:extension_kind)).to be_truthy
    end
  end
end
