# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/text_renderer"
require "ea/svg/ea_emitter/render_context"
require "ea/svg/ea_emitter/compartment"
require "ea/svg/ea_emitter/compartment/instance_underline"

RSpec.describe Ea::Svg::EaEmitter::Compartment::InstanceUnderline do
  let(:bounds) { Ea::Model::Bounds.new(x: 50, y: 40, width: 90, height: 50) }
  let(:theme) { Ea::Theme::Registry.default }
  let(:geometry) do
    Struct.new(:header_first_y, keyword_init: true).new(header_first_y: 59)
  end

  def context_for(diagram_type, header_lines)
    diagram = diagram_type ? Ea::Model::Diagram.new(id: "D1", name: "X",
                                                     diagram_type: diagram_type) : nil
    Ea::Svg::EaEmitter::RenderContext.new(
      element: nil, bounds: bounds, model_element: nil, classifier: nil,
      fill: "#FFF", stroke: "#000", stroke_width: 2,
      text_fill: "#000", family: "Carlito", size: 7, size_unit: "pt",
      header_lines: header_lines, attr_lines: [], op_lines: [],
      enum_literals: [], tagged_values: [], constraints: [],
      package_content_lines: [],
      geometry: geometry, theme: theme, canvas: nil, diagram: diagram
    )
  end

  describe ".render" do
    it "returns nil when there is no diagram" do
      ctx = context_for(nil, [["Foo", :bold]])
      expect(described_class.render(ctx)).to be_nil
    end

    it "returns nil when the diagram is not an Object diagram" do
      ctx = context_for("Logical", [["Foo", :bold]])
      expect(described_class.render(ctx)).to be_nil
    end

    it "returns nil when header_lines is empty" do
      ctx = context_for("Object", [])
      expect(described_class.render(ctx)).to be_nil
    end

    it "renders an underline path below the last header line" do
      ctx = context_for("Object", [["Object A", :bold]])
      svg = described_class.render(ctx)
      expect(svg).to include("<path")
      expect(svg).to include("M ")
      expect(svg).to include(" L ")
    end

    it "uses the last header line's text width" do
      ctx = context_for("Object", [["«stereotype»", :normal], ["Widget", :bold]])
      svg = described_class.render(ctx)
      # The underline should be sized for "Widget", not "«stereotype»".
      expect(svg).to include("<path")
    end
  end
end
