# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/compartment"
require "ea/svg/ea_emitter/render_context"

RSpec.describe Ea::Svg::EaEmitter::Compartment do
  describe "::ALL" do
    it "lists compartments in EA's render order" do
      expected = [
        Ea::Svg::EaEmitter::Compartment::Shape,
        Ea::Svg::EaEmitter::Compartment::NoteBody,
        Ea::Svg::EaEmitter::Compartment::Header,
        Ea::Svg::EaEmitter::Compartment::HeaderDivider,
        Ea::Svg::EaEmitter::Compartment::StereotypeIcon,
        Ea::Svg::EaEmitter::Compartment::Attributes,
        Ea::Svg::EaEmitter::Compartment::Operations,
        Ea::Svg::EaEmitter::Compartment::EnumLiterals,
        Ea::Svg::EaEmitter::Compartment::TaggedValues,
        Ea::Svg::EaEmitter::Compartment::Constraints,
        Ea::Svg::EaEmitter::Compartment::PackageContents,
        Ea::Svg::EaEmitter::Compartment::InstanceSlots,
        Ea::Svg::EaEmitter::Compartment::NoteText,
        Ea::Svg::EaEmitter::Compartment::PackageFromParent,
        Ea::Svg::EaEmitter::Compartment::InstanceUnderline
      ]
      expect(described_class::ALL).to eq(expected)
    end

    it "is frozen (no mutation at runtime)" do
      expect(described_class::ALL).to be_frozen
    end
  end

  describe ".render_all" do
    let(:bounds) { Ea::Model::Bounds.new(x: 10, y: 20, width: 100, height: 80) }
    let(:classifier) { Ea::Model::Klass.new(id: "C1", name: "Widget") }
    let(:theme) { Ea::Theme::Registry.default }

    let(:context) do
      Ea::Svg::EaEmitter::RenderContext.new(
        element: nil,
        bounds: bounds,
        model_element: classifier,
        classifier: classifier,
        fill: "#FFFFFF", stroke: "#000000", stroke_width: 2,
        text_fill: "#000000",
        family: "Carlito", size: 7, size_unit: "pt",
        header_lines: [],
        attr_lines: [],
        op_lines: [],
        enum_literals: [],
        tagged_values: [],
        geometry: nil,
        theme: theme,
        canvas: nil
      )
    end

    it "returns an Array with one entry per compartment" do
      results = described_class.render_all(context)
      expect(results.size).to eq(described_class::ALL.size)
    end

    it "includes the shape layer for a classifier" do
      results = described_class.render_all(context)
      shape_svg = results.first
      expect(shape_svg).to include("<rect")
    end

    it "returns nil for compartments that have no content" do
      # Header, Attribute, etc. should be nil when there are no lines.
      results = described_class.render_all(context)
      expect(results[Compartment_index_of(:Header)]).to be_nil
      expect(results[Compartment_index_of(:Attributes)]).to be_nil
    end

    def Compartment_index_of(name)
      described_class::ALL.index(Ea::Svg::EaEmitter::Compartment.const_get(name))
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::RenderContext do
  let(:bounds) { Ea::Model::Bounds.new(x: 0, y: 0, width: 50, height: 50) }
  let(:theme) { Ea::Theme::Registry.default }

  it "exposes note_body as nil for non-Note elements" do
    klass = Ea::Model::Klass.new(id: "K1", name: "X")
    ctx = described_class.new(
      element: nil, bounds: bounds, model_element: klass,
      classifier: klass, fill: "#FFF", stroke: "#000", stroke_width: 2,
      text_fill: "#000", family: "Carlito", size: 7, size_unit: "pt",
      header_lines: [], attr_lines: [], op_lines: [],
      enum_literals: [], tagged_values: [],
      geometry: nil, theme: theme, canvas: nil
    )
    expect(ctx.note_body).to be_nil
  end

  it "exposes note_body as the body string for Note elements" do
    note = Ea::Model::Note.new(id: "N1", name: "Note", body: "Hello")
    ctx = described_class.new(
      element: nil, bounds: bounds, model_element: note,
      classifier: nil, fill: "#FFF", stroke: "#000", stroke_width: 2,
      text_fill: "#000", family: "Carlito", size: 7, size_unit: "pt",
      header_lines: [], attr_lines: [], op_lines: [],
      enum_literals: [], tagged_values: [],
      geometry: nil, theme: theme, canvas: nil
    )
    expect(ctx.note_body).to eq("Hello")
  end

  it "exposes content_below_header? based on the compartment line counts" do
    ctx = described_class.new(
      element: nil, bounds: bounds, model_element: nil, classifier: nil,
      fill: "#FFF", stroke: "#000", stroke_width: 2,
      text_fill: "#000", family: "Carlito", size: 7, size_unit: "pt",
      header_lines: [], attr_lines: [], op_lines: [],
      enum_literals: [], tagged_values: [],
      geometry: nil, theme: theme, canvas: nil
    )
    expect(ctx.content_below_header?).to be(false)

    ctx2 = described_class.new(
      element: nil, bounds: bounds, model_element: nil, classifier: nil,
      fill: "#FFF", stroke: "#000", stroke_width: 2,
      text_fill: "#000", family: "Carlito", size: 7, size_unit: "pt",
      header_lines: [], attr_lines: ["+ foo"], op_lines: [],
      enum_literals: [], tagged_values: [],
      geometry: nil, theme: theme, canvas: nil
    )
    expect(ctx2.content_below_header?).to be(true)
  end
end
