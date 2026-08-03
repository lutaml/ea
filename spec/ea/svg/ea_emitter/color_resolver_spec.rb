# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::ColorResolver do
  let(:default_theme) { Ea::Theme::Registry.default }
  let(:theme_119) { Ea::Theme::Registry.lookup("119") }

  describe "#fill_for with default theme" do
    let(:resolver) { described_class.new(theme: default_theme) }
    let(:element_with_bcol) do
      Ea::Model::DiagramElement.new(id: "e1", background_color: 0x00FFCC)
    end
    let(:element_no_bcol) { Ea::Model::DiagramElement.new(id: "e2") }
    let(:classifier_with_stereotype) do
      Ea::Model::Klass.new(id: "c1", name: "X", stereotype_refs: ["FeatureType"])
    end
    let(:classifier_no_stereotype) do
      Ea::Model::Klass.new(id: "c2", name: "Y")
    end

    it "returns BCol when present (highest precedence)" do
      fill = resolver.fill_for(element_with_bcol, classifier_with_stereotype)
      # BGR encoding: 0x00FFCC → R=CC, G=FF, B=00 → #CCFF00
      expect(fill).to eq("#CCFF00")
    end

    it "returns stereotype color when no BCol" do
      fill = resolver.fill_for(element_no_bcol, classifier_with_stereotype)
      expect(fill).to start_with("#")
    end

    it "returns default fill when no BCol and no stereotype" do
      fill = resolver.fill_for(element_no_bcol, classifier_no_stereotype)
      expect(fill).to eq(described_class::DEFAULT_FILL)
    end

    it "returns default fill when no classifier" do
      fill = resolver.fill_for(element_no_bcol, nil)
      expect(fill).to eq(described_class::DEFAULT_FILL)
    end
  end

  describe "#fill_for with theme :119" do
    let(:resolver) { described_class.new(theme: theme_119) }
    let(:element_no_bcol) { Ea::Model::DiagramElement.new(id: "e1") }

    it "returns default fill for Klass (theme colors not applied)" do
      klass = Ea::Model::Klass.new(id: "c1", name: "X")
      expect(resolver.fill_for(element_no_bcol, klass)).to eq(described_class::DEFAULT_FILL)
    end

    it "returns default fill for Enumeration (theme colors not applied)" do
      enum = Ea::Model::Enumeration.new(id: "c2", name: "Enum")
      expect(resolver.fill_for(element_no_bcol, enum)).to eq(described_class::DEFAULT_FILL)
    end

    it "still honors BCol when present" do
      element_with_bcol = Ea::Model::DiagramElement.new(id: "e1", background_color: 0xFF0000)
      fill = resolver.fill_for(element_with_bcol, Ea::Model::Klass.new(id: "c", name: "X"))
      expect(fill).to eq("#0000FF") # BGR → R=00, G=00, B=FF
    end
  end

  describe "#stroke_for" do
    it "returns LCol when present" do
      element = Ea::Model::DiagramElement.new(id: "e", line_color: 0xFF0000)
      resolver = described_class.new(theme: default_theme)
      expect(resolver.stroke_for(element)).to eq("#0000FF")
    end

    it "returns theme border color when themed" do
      element = Ea::Model::DiagramElement.new(id: "e")
      resolver = described_class.new(theme: theme_119)
      expect(resolver.stroke_for(element)).to eq("#9A8484")
    end

    it "returns default stroke when no LCol and default theme" do
      element = Ea::Model::DiagramElement.new(id: "e")
      resolver = described_class.new(theme: default_theme)
      expect(resolver.stroke_for(element)).to eq(described_class::DEFAULT_STROKE)
    end
  end
end
