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
    it "emits an italic 'constraints' header followed by {name} lines" do
      svg = described_class.render([constraint], bounds: bounds,
                                     first_y: 240, family: "Carlito", size: 7)
      expect(svg).to include(">constraints</text>")
      expect(svg).to include(">{pattern}</text>")
      expect(svg).to include("italic")
    end

    it "wraps the output in a <g> element" do
      svg = described_class.render([constraint], bounds: bounds,
                                     first_y: 240, family: "Carlito", size: 7)
      expect(svg).to start_with(%(<g style="))
      expect(svg).to end_with("</g>")
    end

    it "renders one {name} line per constraint" do
      constraints = [
        Ea::Model::Constraint.new(name: "alpha"),
        Ea::Model::Constraint.new(name: "beta")
      ]
      svg = described_class.render(constraints, bounds: bounds,
                                     first_y: 240, family: "Carlito", size: 7)
      expect(svg).to include("{alpha}")
      expect(svg).to include("{beta}")
    end
  end
end
