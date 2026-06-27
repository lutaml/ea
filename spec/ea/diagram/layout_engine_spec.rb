# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Diagram::LayoutEngine do
  let(:engine) { described_class.new }
  let(:custom_engine) do
    described_class.new(
      spacing: 100,
      element_width: 200,
      element_height: 150,
    )
  end

  describe "#initialize" do
    it "uses default values when no options provided", :aggregate_failures do
      expect(engine.spacing).to eq(50)
      expect(engine.element_width).to eq(120)
      expect(engine.element_height).to eq(80)
    end

    it "accepts custom spacing value" do
      expect(custom_engine.spacing).to eq(100)
    end

    it "accepts custom element dimensions", :aggregate_failures do
      expect(custom_engine.element_width).to eq(200)
      expect(custom_engine.element_height).to eq(150)
    end
  end

  describe "#calculate_bounds" do
    context "with no elements" do
      it "returns default bounds" do
        diagram_data = { elements: [], connectors: [] }

        result = engine.calculate_bounds(diagram_data)

        expect(result).to eq({
                               x: 0,
                               y: 0,
                               width: 400,
                               height: 300,
                             })
      end
    end

    context "with single element" do
      it "calculates bounds including padding", :aggregate_failures do
        diagram_data = {
          elements: [
            { id: "1", x: 100, y: 50, width: 200, height: 100 },
          ],
          connectors: [],
        }

        result = engine.calculate_bounds(diagram_data)

        # Should include element plus padding (5% or 20px, whichever larger)
        expect(result[:x]).to be < 100
        expect(result[:y]).to be < 50
        expect(result[:x] + result[:width]).to be > 300  # 100 + 200
        expect(result[:y] + result[:height]).to be > 150 # 50 + 100
      end
    end

    context "with multiple elements" do
      it "calculates bounds including all elements", :aggregate_failures do
        diagram_data = {
          elements: [
            { id: "1", x: 100, y: 50, width: 200, height: 100 },
            { id: "2", x: 400, y: 200, width: 150, height: 80 },
          ],
          connectors: [],
        }

        result = engine.calculate_bounds(diagram_data)

        # Should include all elements plus padding
        expect(result[:x]).to be < 100
        expect(result[:y]).to be < 50
        expect(result[:x] + result[:width]).to be > 550  # 400 + 150
        expect(result[:y] + result[:height]).to be > 280 # 200 + 80
      end
    end

    context "with connectors" do
      it "includes connector endpoints in bounds", :aggregate_failures do
        source_element = { id: "1", x: 100, y: 50, width: 200, height: 100 }
        target_element = { id: "2", x: 400, y: 200, width: 150, height: 80 }

        diagram_data = {
          elements: [source_element, target_element],
          connectors: [
            {
              id: "c1",
              geometry: "SX=50;SY=25;EX=-30;EY=20;EDGE=1;",
              source_element: source_element,
              target_element: target_element,
            },
          ],
        }

        result = engine.calculate_bounds(diagram_data)

        # Connector endpoints:
        # Source: (100 + 200/2, 50 + 100/2) + (50, 25) = (250, 125)
        # Target: (400 + 150/2, 200 + 80/2) + (-30, 20) = (445, 260)
        # Both should be within bounds
        expect(result[:x]).to be <= 100
        expect(result[:y]).to be <= 50
        expect(result[:x] + result[:width]).to be >= 550
        expect(result[:y] + result[:height]).to be >= 280
      end

      it "handles connectors without geometry gracefully" do
        diagram_data = {
          elements: [
            { id: "1", x: 100, y: 50, width: 200, height: 100 },
          ],
          connectors: [
            { id: "c1", geometry: nil },
          ],
        }

        expect { engine.calculate_bounds(diagram_data) }.not_to raise_error
      end
    end

    context "with negative coordinates" do
      it "normalizes negative coordinates before calculating bounds",
         :aggregate_failures do
        diagram_data = {
          elements: [
            { id: "1", x: -100, y: -50, width: 200, height: 100 },
            { id: "2", x: 50, y: 30, width: 150, height: 80 },
          ],
          connectors: [],
        }

        result = engine.calculate_bounds(diagram_data)

        # After normalization, first element should be at (0, 0)
        # Bounds should start from negative padding value
        expect(result[:x]).to be < 0
        expect(result[:y]).to be < 0
      end
    end

    context "with padding calculation" do
      it "uses 5% padding for large diagrams", :aggregate_failures do
        diagram_data = {
          elements: [
            { id: "1", x: 0, y: 0, width: 1000, height: 800 },
          ],
          connectors: [],
        }

        result = engine.calculate_bounds(diagram_data)

        # 5% of 1000 = 50, so padding should be 50
        expect(result[:x]).to eq(-50)
        expect(result[:y]).to eq(-40) # 5% of 800 = 40
      end

      it "uses minimum 20px padding for small diagrams", :aggregate_failures do
        diagram_data = {
          elements: [
            { id: "1", x: 0, y: 0, width: 100, height: 80 },
          ],
          connectors: [],
        }

        result = engine.calculate_bounds(diagram_data)

        # 5% of 100 = 5, but minimum is 20
        expect(result[:x]).to eq(-20)
        expect(result[:y]).to eq(-20)
      end
    end
  end

  describe "#apply_layout" do
    context "with all positioned elements" do
      it "returns elements unchanged" do
        elements = [
          { id: "1", x: 100, y: 50 },
          { id: "2", x: 300, y: 150 },
        ]

        result = engine.apply_layout(elements, [])

        expect(result).to eq(elements)
      end
    end

    context "with unpositioned elements" do
      it "calculates positions for elements without x/y", :aggregate_failures do
        elements = [
          { id: "1", x: 100, y: 50 },
          { id: "2" }, # No position
        ]

        result = engine.apply_layout(elements, [])

        expect(result.size).to eq(2)
        expect(result[1]).to have_key(:x)
        expect(result[1]).to have_key(:y)
        expect(result[1][:x]).to be_a(Numeric)
        expect(result[1][:y]).to be_a(Numeric)
      end

      it "positions multiple unpositioned elements in a grid",
         :aggregate_failures do
        elements = [
          { id: "1" },
          { id: "2" },
          { id: "3" },
          { id: "4" },
        ]

        result = engine.apply_layout(elements, [])

        expect(result.size).to eq(4)
        expect(result).to all(have_key(:x))
        expect(result).to all(have_key(:y))
      end
    end

    context "with connectors" do
      it "accepts connectors parameter without error" do
        elements = [{ id: "1", x: 100, y: 50 }]
        connectors = [{ id: "c1", source: "1", target: "2" }]

        expect { engine.apply_layout(elements, connectors) }.not_to raise_error
      end
    end
  end

  describe "#calculate_element_position" do
    context "with existing position" do
      it "returns element unchanged" do
        element = { id: "1", x: 100, y: 50 }

        result = engine.calculate_element_position(element, [])

        expect(result).to eq(element)
      end
    end

    context "without position and no related elements" do
      it "positions at origin", :aggregate_failures do
        element = { id: "1" }

        result = engine.calculate_element_position(element, [])

        expect(result[:x]).to eq(0)
        expect(result[:y]).to eq(0)
      end
    end

    context "without position but with related elements" do
      it "positions to the right of related elements", :aggregate_failures do
        element = { id: "2" }
        related = [{ id: "1", x: 100, y: 50, width: 120 }]

        result = engine.calculate_element_position(element, related)

        # Should be positioned: 100 + 120 + spacing (50) = 270
        expect(result[:x]).to eq(270)
        expect(result[:y]).to eq(50) # Same y as related
      end

      it "uses element_width_for when related element has no width",
         :aggregate_failures do
        element = { id: "2" }
        related = [{ id: "1", x: 100, y: 50, type: "class" }]

        result = engine.calculate_element_position(element, related)

        # Should use default ELEMENT_WIDTH (120) + spacing (50)
        expect(result[:x]).to be > 100
        expect(result[:y]).to eq(50)
      end
    end
  end

  describe "private methods" do
    describe "#element_width_for" do
      it "returns actual width when available and positive" do
        element = { width: 200 }
        expect(engine.element_width_for(element)).to eq(200)
      end

      it "calculates width for class type based on attributes" do
        element = { type: "class", attributes: [{}, {}, {}] }
        width = engine.element_width_for(element)
        expect(width).to eq(150) # 3 * 10 + 120
      end

      it "calculates width for package type" do
        element = { type: "package" }
        width = engine.element_width_for(element)
        expect(width).to eq(140) # ELEMENT_WIDTH + 20
      end

      it "returns default width for unknown types" do
        element = { type: "unknown" }
        width = engine.element_width_for(element)
        expect(width).to eq(120) # ELEMENT_WIDTH
      end

      it "uses default when width is zero" do
        element = { width: 0, type: "class" }
        width = engine.element_width_for(element)
        expect(width).to eq(120)
      end
    end

    describe "#element_height_for" do
      it "returns actual height when available and positive" do
        element = { height: 150 }
        expect(engine.element_height_for(element)).to eq(150)
      end

      it "calculates height for class type based on operations" do
        element = { type: "class", operations: [{}, {}] }
        height = engine.element_height_for(element)
        expect(height).to eq(110) # 2 * 15 + 80
      end

      it "calculates height for package type" do
        element = { type: "package" }
        height = engine.element_height_for(element)
        expect(height).to eq(70) # ELEMENT_HEIGHT - 10
      end

      it "returns default height for unknown types" do
        element = { type: "unknown" }
        height = engine.element_height_for(element)
        expect(height).to eq(80) # ELEMENT_HEIGHT
      end
    end

    describe "#calculate_connector_bounds" do
      it "returns nil when connectors array is empty" do
        result = engine.calculate_connector_bounds([])
        expect(result).to be_nil
      end

      it "returns nil when no valid connectors" do
        connectors = [
          { id: "c1", geometry: "SX=0;SY=0;EX=0;EY=0;" },
          # Missing source_element and target_element
        ]
        result = engine.calculate_connector_bounds(connectors)
        expect(result).to be_nil
      end

      it "calculates bounds for connectors with geometry",
         :aggregate_failures do
        source = { id: "1", x: 100, y: 50, width: 200, height: 100 }
        target = { id: "2", x: 400, y: 200, width: 150, height: 80 }

        connectors = [
          {
            id: "c1",
            geometry: "SX=10;SY=5;EX=-10;EY=-5;",
            source_element: source,
            target_element: target,
          },
        ]

        result = engine.calculate_connector_bounds(connectors)

        expect(result).to be_a(Hash)
        expect(result).to have_key(:min_x)
        expect(result).to have_key(:max_x)
        expect(result).to have_key(:min_y)
        expect(result).to have_key(:max_y)
      end
    end

    describe "#parse_geometry_offsets" do
      it "parses EA geometry string correctly", :aggregate_failures do
        geometry = "SX=10;SY=5;EX=-10;EY=-5;EDGE=1;"
        sx, sy, ex, ey = engine.parse_geometry_offsets(geometry)

        expect(sx).to eq(10)
        expect(sy).to eq(5)
        expect(ex).to eq(-10)
        expect(ey).to eq(-5)
      end

      it "handles missing values with defaults", :aggregate_failures do
        geometry = "SX=10;EDGE=1;"
        sx, sy, ex, ey = engine.parse_geometry_offsets(geometry)

        expect(sx).to eq(10)
        expect(sy).to eq(0)
        expect(ex).to eq(0)
        expect(ey).to eq(0)
      end

      it "returns zeros for nil geometry" do
        sx, sy, ex, ey = engine.parse_geometry_offsets(nil)

        expect([sx, sy, ex, ey]).to eq([0, 0, 0, 0])
      end

      it "returns zeros for empty geometry" do
        sx, sy, ex, ey = engine.parse_geometry_offsets("")

        expect([sx, sy, ex, ey]).to eq([0, 0, 0, 0])
      end

      it "handles malformed geometry gracefully" do
        geometry = "INVALID;FORMAT;"
        sx, sy, ex, ey = engine.parse_geometry_offsets(geometry)

        expect([sx, sy, ex, ey]).to eq([0, 0, 0, 0])
      end

      it "handles geometry with extra whitespace", :aggregate_failures do
        geometry = " SX = 10 ; SY = 5 ; "
        sx, sy, _ex, _ey = engine.parse_geometry_offsets(geometry)

        expect(sx).to eq(10)
        expect(sy).to eq(5)
      end
    end
  end
end
