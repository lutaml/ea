# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Diagram::ElementRenderers::ConnectorRenderer do
  let(:style_resolver) { Ea::Diagram::StyleResolver.new }
  let(:connector_data) do
    {
      id: "conn-1",
      type: "association",
      source: "elem-1",
      target: "elem-2",
      geometry: "SX=10;SY=5;EX=-10;EY=-5;EDGE=1;",
    }
  end
  let(:source_element) do
    { id: "elem-1", x: 100, y: 50, width: 120, height: 80 }
  end
  let(:target_element) do
    { id: "elem-2", x: 400, y: 200, width: 150, height: 100 }
  end
  let(:renderer) do
    described_class.new(connector_data, style_resolver, source_element,
                        target_element)
  end

  describe "inheritance" do
    it "inherits from BaseRenderer" do
      expect(described_class).to be < Ea::Diagram::ElementRenderers::BaseRenderer
    end
  end

  describe "#initialize" do
    it "calls super to initialize element and style_resolver" do
      expect(renderer.element).to eq(connector_data)
      expect(renderer.style_resolver).to eq(style_resolver)
    end

    it "stores source element" do
      expect(renderer.source_element).to eq(source_element)
    end

    it "stores target element" do
      expect(renderer.target_element).to eq(target_element)
    end

    it "accepts nil source element" do
      renderer_no_source = described_class.new(connector_data,
                                               style_resolver,
                                               nil, target_element)
      expect(renderer_no_source.source_element).to be_nil
    end

    it "accepts nil target element" do
      renderer_no_target = described_class.new(connector_data,
                                               style_resolver,
                                               source_element, nil)
      expect(renderer_no_target.target_element).to be_nil
    end
  end

  describe "#render" do
    it "returns SVG path element", :aggregate_failures do
      svg = renderer.render

      expect(svg).to include("<path")
      expect(svg).to include("d=")
    end

    it "includes connector ID in data attribute" do
      svg = renderer.render

      expect(svg).to include('data-connector-id="conn-1"')
    end

    it "includes connector type in data attribute" do
      svg = renderer.render

      expect(svg).to include('data-connector-type="association"')
    end

    it "includes base connector class" do
      svg = renderer.render

      expect(svg).to include('class="lutaml-diagram-connector')
    end

    it "includes type-specific connector class" do
      svg = renderer.render

      expect(svg).to include("lutaml-diagram-connector-association")
    end

    it "includes arrowhead marker reference" do
      svg = renderer.render

      expect(svg).to include('marker-end="url(#arrowhead)"')
    end

    it "includes path data from PathBuilder" do
      svg = renderer.render

      expect(svg).to match(/d="M \d+,\d+/)
    end

    context "with generalization connector" do
      before do
        connector_data[:type] = "generalization"
      end

      it "includes generalization class" do
        svg = renderer.render

        expect(svg).to include("lutaml-diagram-connector-generalization")
      end
    end

    context "with dependency connector" do
      before do
        connector_data[:type] = "dependency"
      end

      it "includes dependency class" do
        svg = renderer.render

        expect(svg).to include("lutaml-diagram-connector-dependency")
      end
    end

    context "with composition connector" do
      before do
        connector_data[:type] = "composition"
      end

      it "includes composition class" do
        svg = renderer.render

        expect(svg).to include("lutaml-diagram-connector-composition")
      end
    end
  end

  describe "integration with PathBuilder" do
    it "uses EA geometry to build path" do
      svg = renderer.render

      expect(svg).to match(/d="M \d+,\d+ L \d+,\d+/)
    end

    it "handles connector without geometry" do
      connector_data.delete(:geometry)

      expect { renderer.render }.not_to raise_error
    end

    it "handles connector with waypoints" do
      connector_data[:geometry] = "SX=0;SY=0;EX=0;EY=0;EDGE=1;EDGE1=250,125;"

      svg = renderer.render

      expect(svg).to include("250,125")
    end
  end

  describe "edge cases" do
    it "handles missing source element gracefully" do
      renderer_no_source = described_class.new(
        connector_data,
        style_resolver,
        nil,
        target_element,
      )

      expect { renderer_no_source.render }.not_to raise_error
    end

    it "handles missing target element gracefully" do
      renderer_no_target = described_class.new(
        connector_data,
        style_resolver,
        source_element,
        nil,
      )

      expect { renderer_no_target.render }.not_to raise_error
    end

    it "handles missing both elements" do
      renderer_no_elements = described_class.new(
        connector_data,
        style_resolver,
        nil,
        nil,
      )

      expect { renderer_no_elements.render }.not_to raise_error
    end

    it "handles connector without ID" do
      connector_data.delete(:id)

      svg = renderer.render

      expect(svg).to include("<path")
    end

    it "handles connector without type" do
      connector_data.delete(:type)

      svg = renderer.render

      expect(svg).to include('class="lutaml-diagram-connector')
    end
  end
end
