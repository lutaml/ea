# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/elements"
require "ea/model/diagram"

RSpec.describe Ea::Svg::EaEmitter::Elements do
  let(:diagram) do
    Ea::Model::Diagram.new(
      id: "D1", name: "Test",
      show_package_contents: true,
      elements: [],
      connectors: []
    )
  end

  let(:model_index) do
    {
      "PKG1" => Ea::Model::Package.new(id: "PKG1", name: "Outer"),
      "SUB1" => Ea::Model::Package.new(id: "SUB1", name: "Sub", parent_id: "PKG1"),
      "KLS1" => Ea::Model::Klass.new(id: "KLS1", name: "Widget",
                                       package_id: "PKG1",
                                       stereotype_refs: []),
      "ENM1" => Ea::Model::Enumeration.new(id: "ENM1", name: "Color",
                                            package_id: "PKG1",
                                            stereotype_refs: []),
      "ENMS" => Ea::Model::Klass.new(id: "ENMS", name: "Status",
                                       package_id: "PKG1",
                                       stereotype_refs: ["enumeration"])
    }
  end

  let(:elements) { described_class.new(diagram, model_index: model_index) }

  describe "#package_content_lines_for" do
    it "returns [] when model_element is not a Package" do
      result = elements.send(:package_content_lines_for, model_index["KLS1"])
      expect(result).to eq([])
    end

    it "returns [] when show_package_contents is false" do
      diagram.show_package_contents = false
      result = elements.send(:package_content_lines_for, model_index["PKG1"])
      expect(result).to eq([])
    end

    it "returns alphabetical rows for each child" do
      rows = elements.send(:package_content_lines_for, model_index["PKG1"])
      names = rows.map(&:name)
      expect(names).to eq(%w[Color Status Sub Widget])
    end

    it "includes both classifier and sub-package children" do
      rows = elements.send(:package_content_lines_for, model_index["PKG1"])
      kinds = rows.map { |r| [r.name, r.kind] }.to_h
      expect(kinds["Sub"]).to eq(:package)
      expect(kinds["Widget"]).to eq(:default)
      expect(kinds["Color"]).to eq(:enumeration)
    end

    it "uses :enumeration kind for classifiers with 'enumeration' stereotype" do
      rows = elements.send(:package_content_lines_for, model_index["PKG1"])
      status_row = rows.find { |r| r.name == "Status" }
      expect(status_row.kind).to eq(:enumeration)
    end
  end
end