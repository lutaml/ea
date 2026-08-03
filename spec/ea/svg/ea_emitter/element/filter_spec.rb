# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/element/filter"

RSpec.describe Ea::Svg::EaEmitter::Element::Filter do
  let(:classifier) { Ea::Model::Klass.new(id: "C1", name: "Named") }
  let(:model_index) { { "C1" => classifier } }

  let(:filter) { described_class.new(model_index: model_index) }

  def build_element(attrs = {})
    defaults = { model_element_ref: "C1", background_color: 16_777_215 }
    Ea::Model::DiagramElement.new(defaults.merge(attrs))
  end

  describe "#skip?" do
    it "returns false for a named, white-bg classifier" do
      expect(filter.skip?(build_element)).to be(false)
    end

    it "returns false for a foreign element not in the index" do
      el = build_element(model_element_ref: "MISSING")
      expect(filter.skip?(build_element)).to be(false)
    end

    it "returns true when bg=-1, name empty, no properties" do
      empty = Ea::Model::Klass.new(id: "EMPTY", name: "")
      idx = { "EMPTY" => empty }
      f = described_class.new(model_index: idx)
      el = Ea::Model::DiagramElement.new(model_element_ref: "EMPTY",
                                          background_color: -1)
      expect(f.skip?(el)).to be(true)
    end

    it "returns false when bg=-1 but classifier has a name" do
      named = Ea::Model::Klass.new(id: "NAMED", name: "Named")
      idx = { "NAMED" => named }
      f = described_class.new(model_index: idx)
      el = Ea::Model::DiagramElement.new(model_element_ref: "NAMED",
                                          background_color: -1)
      expect(f.skip?(el)).to be(false)
    end

    it "returns false when bg=-1 but classifier has properties" do
      with_props = Ea::Model::Klass.new(id: "WP", name: "",
                                          properties: [
                                            Ea::Model::Property.new(name: "p")
                                          ])
      idx = { "WP" => with_props }
      f = described_class.new(model_index: idx)
      el = Ea::Model::DiagramElement.new(model_element_ref: "WP",
                                          background_color: -1)
      expect(f.skip?(el)).to be(false)
    end

    it "returns false when bg != -1 even if name is empty" do
      empty = Ea::Model::Klass.new(id: "E", name: "")
      idx = { "E" => empty }
      f = described_class.new(model_index: idx)
      el = Ea::Model::DiagramElement.new(model_element_ref: "E",
                                          background_color: 0)
      expect(f.skip?(el)).to be(false)
    end
  end
end
