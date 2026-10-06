# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Compartment::InstanceSlots do
  GUID = "{11111111-2222-3333-4444-555555555555}"

  def make_context(instance, diagram)
    Struct.new(:model_element, :diagram).new(instance, diagram)
  end

  def make_instance(package_id: GUID)
    Ea::Model::InstanceSpecification.new(
      name: "SU_PB2",
      classifier_name: "LA_SpatialUnit",
      package_id: package_id,
      package_name: "FIG2010"
    )
  end

  def make_diagram(package_id: GUID)
    Struct.new(:package_id).new(package_id)
  end

  describe ".from_package_subtitle" do
    it "returns nil for an instance local to the diagram's package" do
      ctx = make_context(make_instance, make_diagram)
      expect(described_class.from_package_subtitle(ctx.model_element,
                                                   ctx.diagram)).to be_nil
    end

    it "returns the subtitle for a foreign-package instance" do
      other = "{99999999-8888-7777-6666-555555555555}"
      ctx = make_context(make_instance(package_id: other), make_diagram)
      expect(described_class.from_package_subtitle(ctx.model_element,
                                                   ctx.diagram))
        .to eq("(from FIG2010)")
    end

    it "returns nil when the classifier is nil" do
      inst = Ea::Model::InstanceSpecification.new(
        name: "x", package_name: "FIG2010"
      )
      expect(described_class.from_package_subtitle(inst, make_diagram))
        .to be_nil
    end
  end
end
