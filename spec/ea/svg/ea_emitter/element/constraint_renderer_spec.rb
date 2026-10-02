# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/element/constraint_renderer"

RSpec.describe Ea::Svg::EaEmitter::Element::ConstraintRenderer do
  let(:bounds) { Ea::Model::Bounds.new(x: 35, y: 60, width: 134, height: 174) }
  let(:constraint) do
    Ea::Model::Constraint.new(name: "pattern", kind: "OCL",
                              body: "inv: ...", status: "Approved")
  end

  describe ".render" do
    it "emits bare {name} lines with no caption" do
      svg = described_class.render([constraint], bounds: bounds,
                                     first_y: 240, family: "Carlito", size: 7)
      expect(svg).not_to include(">constraints</text>")
      expect(svg).to include(">{pattern}</text>")
      expect(svg).to start_with(%(<g style="))
      expect(svg).to end_with("</g>")
    end

    it "right-aligns each line to the box right edge" do
      svg = described_class.render([constraint], bounds: bounds,
                                     first_y: 240, family: "Carlito", size: 7)
      len = Ea::Svg::EaEmitter::TextRenderer.estimate_width("{pattern}", 7, nil,
                                                            family: "Carlito").round
      expect(svg).to include(%(x="#{bounds.x + bounds.width - len}.00"))
    end

    it "spaces lines at the compartment pitch (size + 6)" do
      constraints = [
        Ea::Model::Constraint.new(name: "alpha"),
        Ea::Model::Constraint.new(name: "beta")
      ]
      svg = described_class.render(constraints, bounds: bounds,
                                     first_y: 240, family: "Carlito", size: 7)
      ys = svg.scan(/y="([\d.]+)"/).flatten.map(&:to_f)
      expect(ys).to eq([240, 253])
    end
  end
end
