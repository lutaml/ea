# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/elements"

RSpec.describe Ea::Svg::EaEmitter::Elements do
  # 936AA434/Surface: EA lists the interface's own attribute rows
  # (nine ISO 19107 attributes incl. derived /area, /perimeter) -
  # the earlier "interfaces never render attributes" rule came from
  # zero-attribute leaf interfaces.
  let(:iface) do
    Ea::Model::Interface.new(
      id: "IF1", name: "Surface", package_id: "PKG1",
      properties: [
        Ea::Model::Property.new(name: "area", type_name: "Area",
                                is_derived: true),
        Ea::Model::Property.new(name: "boundary", type_name: "Curve")
      ]
    )
  end

  let(:model_index) do
    { "IF1" => iface }
  end

  let(:diagram) do
    Ea::Model::Diagram.new(
      id: "D1", name: "Test",
      elements: [
        Ea::Model::DiagramElement.new(
          id: "E1",
          model_element_ref: "IF1",
          bounds: Ea::Model::Bounds.new(x: 10, y: 40, width: 200, height: 90)
        )
      ],
      connectors: []
    )
  end

  it "renders the interface's attribute rows" do
    svg = described_class.new(diagram, model_index: model_index).render
    expect(svg).to include(">boundary: Curve<")
  end

  it "renders derived attributes with the slash prefix" do
    svg = described_class.new(diagram, model_index: model_index).render
    expect(svg).to include(">/area: Area<")
  end
end
