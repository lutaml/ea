# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Model::Diagram do
  describe "#style_ex_flags" do
    it "returns empty hash when style_ex is nil" do
      d = described_class.new(id: "d1", name: "X")
      expect(d.style_ex_flags).to eq({})
    end

    it "returns empty hash when style_ex is empty" do
      d = described_class.new(id: "d1", name: "X", style_ex: "")
      expect(d.style_ex_flags).to eq({})
    end

    it "parses semicolon-separated key=value pairs" do
      d = described_class.new(id: "d1", name: "X",
                               style_ex: "Theme=:119;SuppressFOC=1;AttPkg=1")
      expect(d.style_ex_flags).to eq({
        "Theme" => ":119",
        "SuppressFOC" => "1",
        "AttPkg" => "1"
      })
    end

    it "skips pairs without =" do
      d = described_class.new(id: "d1", name: "X", style_ex: "Foo;Bar=1")
      expect(d.style_ex_flags).to eq({ "Bar" => "1" })
    end

    it "handles values with no equals" do
      d = described_class.new(id: "d1", name: "X", style_ex: "Empty=")
      expect(d.style_ex_flags["Empty"]).to eq("")
    end
  end

  describe "#theme_id" do
    it "returns nil when no Theme flag" do
      d = described_class.new(id: "d1", name: "X", style_ex: "Foo=1")
      expect(d.theme_id).to be_nil
    end

    it "returns the Theme value when present" do
      d = described_class.new(id: "d1", name: "X", style_ex: "Theme=:119")
      expect(d.theme_id).to eq(":119")
    end
  end
end
