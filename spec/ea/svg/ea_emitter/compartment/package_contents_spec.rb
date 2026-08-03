# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/text_renderer"
require "ea/svg/ea_emitter/render_context"

# Reopen Compartment to bring PackageContents into scope before the
# ALL constant is evaluated (autoload ordering).
require "ea/svg/ea_emitter/compartment"
require "ea/svg/ea_emitter/compartment/package_contents"

RSpec.describe Ea::Svg::EaEmitter::Compartment::PackageContents do
  let(:bounds) { Ea::Model::Bounds.new(x: 35, y: 60, width: 134, height: 174) }
  let(:theme) { Ea::Theme::Registry.default }
  let(:geometry) do
    instance_double("Ea::Svg::EaEmitter::Element::CompartmentGeometry",
                    attr_first_y: 92)
  end

  let(:row) { Ea::Svg::EaEmitter::Elements::PackageContentRow.new(name: "Foo", kind: :default) }

  def context_for(rows)
    Ea::Svg::EaEmitter::RenderContext.new(
      element: nil,
      bounds: bounds,
      model_element: nil,
      classifier: nil,
      fill: "#FFFFFF", stroke: "#000000", stroke_width: 2,
      text_fill: "#000000",
      family: "Carlito", size: 7, size_unit: "pt",
      header_lines: [], attr_lines: [], op_lines: [],
      enum_literals: [], tagged_values: [],
      package_content_lines: rows,
      geometry: geometry,
      theme: theme,
      canvas: nil
    )
  end

  describe ".render" do
    it "returns nil when there are no rows" do
      expect(described_class.render(context_for([]))).to be_nil
    end

    it "wraps the output in a <g> with attribute text style" do
      svg = described_class.render(context_for([row]))
      expect(svg).to start_with(%(<g style="))
      expect(svg).to include("fill-opacity:1.00")
    end

    it "emits one <text> per row with '+ Name' content" do
      svg = described_class.render(context_for([row]))
      expect(svg).to include("+ Foo")
      expect(svg.scan(/<text\b/).size).to eq(1)
    end

    it "emits the per-row icon alongside the text" do
      svg = described_class.render(context_for([row]))
      expect(svg).to include("<rect")
    end

    it "uses enumeration icon shape when row kind is :enumeration" do
      enum_row = Ea::Svg::EaEmitter::Elements::PackageContentRow.new(
        name: "E", kind: :enumeration
      )
      svg = described_class.render(context_for([enum_row]))
      expect(svg.scan(/<rect\b/).size).to eq(1)
    end

    it "uses package icon shape when row kind is :package" do
      pkg_row = Ea::Svg::EaEmitter::Elements::PackageContentRow.new(
        name: "P", kind: :package
      )
      svg = described_class.render(context_for([pkg_row]))
      expect(svg.scan(/<rect\b/).size).to eq(1)
      expect(svg.scan(/<path\b/).size).to eq(0)
    end
  end
end