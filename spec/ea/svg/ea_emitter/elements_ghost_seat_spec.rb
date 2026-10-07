# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/elements"

RSpec.describe Ea::Svg::EaEmitter::Elements do
  # 936AA434/Surface: EA seats the interface ghost at box top + 13
  # (ghost 100, «interface» 116 = +16, name 129), while class ghosts
  # share the +13 seat with a +19 pitch to the next line.
  let(:iface) do
    Ea::Model::Interface.new(id: "IF1", name: "Surface", package_id: "PKG1")
  end

  let(:model_index) do
    {
      "IF1" => iface,
      "IF0" => Ea::Model::Interface.new(id: "IF0", name: "Orientable",
                                        package_id: "PKG1"),
      "PKG1" => Ea::Model::Package.new(id: "PKG1", name: "Shapes",
                                       parent_id: "PKG0"),
      "PKG0" => Ea::Model::Package.new(id: "PKG0", name: "Root")
    }
  end

  let(:document) do
    Ea::Model::Document.new(
      relationships: [
        Ea::Model::Generalization.new(id: "G1", specific_id: "IF1",
                                      general_id: "IF0")
      ]
    )
  end

  let(:diagram) do
    Ea::Model::Diagram.new(
      id: "D1", name: "Test", package_id: "PKG0", show_parents: true,
      elements: [
        Ea::Model::DiagramElement.new(
          id: "E1",
          model_element_ref: "IF1",
          bounds: Ea::Model::Bounds.new(x: 10, y: 40, width: 120, height: 60)
        )
      ],
      connectors: []
    )
  end

  def rendered_lines
    svg = described_class.new(diagram, model_index: model_index,
                              document: document).render
    svg.scan(/<text[^>]*y="([\d.]+)"[^>]*>([^<]*)</)
        .map { |y, content| [y.to_f, content.strip] }
  end

  it "seats the interface parent ghost at box top + 13" do
    ghost = rendered_lines.find { |_y, c| c == "Orientable" }
    expect(ghost).to eq([53.0, "Orientable"])
  end

  it "spaces the interface stereotype +3 past the row pitch" do
    stereo = rendered_lines.find { |_y, c| c.include?("interface") }
    expect(stereo.first).to eq(69.0)
  end
  it "tracks the divider one pixel lower on fallback interface headers" do
    with_attr = Ea::Model::Interface.new(
      id: "IF2", name: "Curve", package_id: "PKG1",
      properties: [Ea::Model::Property.new(name: "boundary",
                                           type_name: "Curve")]
    )
    index = model_index.merge("IF2" => with_attr)
    plain = Ea::Model::Diagram.new(
      id: "D2", name: "T", package_id: "PKG0",
      elements: [
        Ea::Model::DiagramElement.new(
          id: "E2",
          model_element_ref: "IF2",
          bounds: Ea::Model::Bounds.new(x: 10, y: 40, width: 200, height: 90)
        )
      ],
      connectors: []
    )
    svg = described_class.new(plain, model_index: index).render
    ys = svg.scan(/<path[^>]*d="M ([\d.]+) ([\d.]+) L/).map { |m| Float(m[1]) }
    # «interface» 53, name 66, divider 75 = name + 9 (class rule: 74)
    expect(ys.min).to eq(75.0)
  end
end
