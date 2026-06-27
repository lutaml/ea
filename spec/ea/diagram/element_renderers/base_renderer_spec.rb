# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Diagram::ElementRenderers::BaseRenderer do
  let(:style_resolver) { Ea::Diagram::StyleResolver.new }

  # Use a real Struct instead of a double (project rule: no doubles)
  ElementStub = Struct.new(:name, :package_name, :stereotype, keyword_init: true)

  let(:element_data) do
    {
      id: "test-1",
      type: "class",
      name: "TestClass",
      x: 100,
      y: 50,
      width: 120,
      height: 80,
      element: ElementStub.new(name: "TestClass",
                               package_name: nil,
                               stereotype: nil),
      diagram_object: nil,
    }
  end
  let(:renderer) { described_class.new(element_data, style_resolver) }

  describe "#initialize" do
    it "stores element data" do
      expect(renderer.element).to eq(element_data)
    end

    it "stores style resolver" do
      expect(renderer.style_resolver).to eq(style_resolver)
    end
  end

  describe "#render" do
    it "returns SVG group element", :aggregate_failures do
      svg = renderer.render

      expect(svg).to include("<g")
      expect(svg).to include("</g>")
    end

    it "includes element type in class attribute" do
      svg = renderer.render

      expect(svg)
        .to include('class="lutaml-diagram-element lutaml-diagram-class"')
    end

    it "includes data attributes for element ID and type",
       :aggregate_failures do
      svg = renderer.render

      expect(svg).to include('data-element-id="test-1"')
      expect(svg).to include('data-element-type="class"')
    end
  end

  describe "#render_shape" do
    it "returns empty string by default" do
      shape = renderer.render_shape({})

      expect(shape).to eq("")
    end

    it "is intended to be overridden in subclasses" do
      expect(renderer.render_shape({})).to be_a(String)
    end
  end

  describe "#render_label" do
    let(:style) do
      {
        font_family: "Arial, sans-serif",
        font_size: 12,
        font_weight: 700,
      }
    end

    it "returns SVG text element", :aggregate_failures do
      label = renderer.render_label(style)

      expect(label).to include("<text")
      expect(label).to include("</text>")
    end

    it "centers text at element center", :aggregate_failures do
      label = renderer.render_label(style)

      expect(label).to include('x="160"')
      expect(label).to include('y="95"')
    end

    it "includes text-anchor middle" do
      label = renderer.render_label(style)

      expect(label).to include('text-anchor="middle"')
    end

    it "includes dominant-baseline middle" do
      label = renderer.render_label(style)

      expect(label).to include('dominant-baseline="middle"')
    end

    it "applies font family from style" do
      label = renderer.render_label(style)

      expect(label).to include('font-family="Arial, sans-serif"')
    end

    it "applies font size from style" do
      label = renderer.render_label(style)

      expect(label).to include('font-size="12"')
    end

    it "applies font weight from style" do
      label = renderer.render_label(style)

      expect(label).to include('font-weight="700"')
    end

    it "defaults font weight to normal when not in style" do
      label = renderer.render_label({})

      expect(label).to include('font-weight="normal"')
    end

    it "includes element name as text content" do
      label = renderer.render_label(style)

      expect(label).to include("TestClass")
    end

    it "escapes text content" do
      element_data[:name] = "Test<Class>& \"Name\""
      label = renderer.render_label(style)

      expect(label).to include("Test&lt;Class&gt;&amp; &quot;Name&quot;")
    end

    it "uses default text color when not in style" do
      label = renderer.render_label(style)

      expect(label).to include('fill="#000000"')
    end

    it "applies text color from style" do
      style[:text_color] = "#FF0000"
      label = renderer.render_label(style)

      expect(label).to include('fill="#FF0000"')
    end

    it "includes lutaml-diagram-label class" do
      label = renderer.render_label(style)

      expect(label).to include('class="lutaml-diagram-label"')
    end

    it "returns empty string when element has no name" do
      element_data[:name] = nil
      label = renderer.render_label(style)

      expect(label).to eq("")
    end

    it "handles missing dimensions by using defaults" do
      element_data.delete(:width)
      element_data.delete(:height)
      label = renderer.render_label(style)

      expect(label).to include("<text")
    end

    it "handles missing coordinates by using zero", :aggregate_failures do
      element_data.delete(:x)
      element_data.delete(:y)
      label = renderer.render_label(style)

      expect(label).to include('x="60"')
      expect(label).to include('y="45"')
    end
  end

  describe "#escape_text" do
    it "escapes ampersand" do
      result = renderer.escape_text("A & B")

      expect(result).to eq("A &amp; B")
    end

    it "escapes less than" do
      result = renderer.escape_text("A < B")

      expect(result).to eq("A &lt; B")
    end

    it "escapes greater than" do
      result = renderer.escape_text("A > B")

      expect(result).to eq("A &gt; B")
    end

    it "escapes double quotes" do
      result = renderer.escape_text('Say "Hello"')

      expect(result).to eq("Say &quot;Hello&quot;")
    end

    it "escapes single quotes" do
      result = renderer.escape_text("It's working")

      expect(result).to eq("It&apos;s working")
    end

    it "escapes multiple special characters" do
      result = renderer.escape_text("<tag attr=\"value\" & 'more'>")

      expect(result)
        .to eq("&lt;tag attr=&quot;value&quot; &amp; &apos;more&apos;&gt;")
    end

    it "returns empty string for nil input" do
      result = renderer.escape_text(nil)

      expect(result).to eq("")
    end

    it "handles empty string" do
      result = renderer.escape_text("")

      expect(result).to eq("")
    end

    it "converts non-string input to string" do
      result = renderer.escape_text(123)

      expect(result).to eq("123")
    end

    it "does not modify text without special characters" do
      result = renderer.escape_text("Plain text")

      expect(result).to eq("Plain text")
    end
  end
end
