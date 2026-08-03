# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::VisibilitySymbol do
  describe ".for" do
    it "maps 'public' to '+'" do
      expect(described_class.for("public")).to eq("+")
    end

    it "maps 'private' to '-'" do
      expect(described_class.for("private")).to eq("-")
    end

    it "maps 'protected' to '#'" do
      expect(described_class.for("protected")).to eq("#")
    end

    it "maps 'package' to '~'" do
      expect(described_class.for("package")).to eq("~")
    end

    it "is case-insensitive" do
      expect(described_class.for("Public")).to eq("+")
      expect(described_class.for("PRIVATE")).to eq("-")
    end

    it "defaults to '+' for nil" do
      expect(described_class.for(nil)).to eq("+")
    end

    it "defaults to '+' for unknown visibility" do
      expect(described_class.for("unknown")).to eq("+")
    end

    it "appends a trailing space with with_space: true" do
      expect(described_class.for("private", with_space: true)).to eq("- ")
      expect(described_class.for("public", with_space: true)).to eq("+ ")
    end

    it "does not append space by default" do
      expect(described_class.for("private")).to eq("-")
    end
  end
end
