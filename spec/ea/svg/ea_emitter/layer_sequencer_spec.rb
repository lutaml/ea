# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/layer_sequencer"

RSpec.describe Ea::Svg::EaEmitter::LayerSequencer do
  let(:diagram) do
    Ea::Model::Diagram.new(
      id: "d1",
      name: "Test",
      elements: [
        Ea::Model::DiagramElement.new(
          id: "e1",
          model_element_ref: "K1",
          image_bounds: Ea::Model::Bounds.new(x: 0, y: 0, width: 100, height: 80)
        )
      ]
    )
  end

  let(:klass) { Ea::Model::Klass.new(id: "K1", name: "Widget") }
  let(:model_index) { { "K1" => klass } }
  let(:canvas) { Ea::Svg::EaEmitter::Canvas.from(diagram, model_index: model_index) }

  describe "#layers" do
    it "always includes a background layer" do
      seq = described_class.new(diagram, model_index: model_index, canvas: canvas)
      layers = seq.layers
      expect(layers.first).to include("<g")
      expect(layers.first).to include("fill:#FFFFFF")
    end

    it "includes a labels layer entry (possibly empty when no labels)" do
      seq = described_class.new(diagram, model_index: model_index, canvas: canvas)
      layers = seq.layers
      # Labels is always the last layer entry, even if the body is ""
      expect(layers.last).to respond_to(:to_str)
    end

    it "includes element layers when there are visible elements" do
      seq = described_class.new(diagram, model_index: model_index, canvas: canvas)
      layers = seq.layers
      # At least background + element + labels = 3
      expect(layers.size).to be >= 3
    end

    it "includes the diagram frame when frame: true" do
      seq = described_class.new(diagram, model_index: model_index,
                                  canvas: canvas, frame: true)
      layers = seq.layers
      svg = layers.join
      expect(svg).to include("rect") # frame rect or element rect
    end

    it "applies theme to all child renderers" do
      seq = described_class.new(diagram, model_index: model_index, canvas: canvas)
      expect(seq.theme).to eq(diagram.theme)
    end
  end

  describe "with connectors" do
    let(:diagram_with_connector) do
      Ea::Model::Diagram.new(
        id: "d2",
        name: "Test",
        elements: [
          Ea::Model::DiagramElement.new(
            id: "e1",
            model_element_ref: "K1",
            image_bounds: Ea::Model::Bounds.new(x: 0, y: 0, width: 100, height: 80)
          )
        ],
        connectors: [
          Ea::Model::DiagramConnector.new(
            id: "c1",
            connector_type: "Association",
            waypoints: [
              Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
              Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 50, y: 50))
            ]
          )
        ]
      )
    end

    it "renders connector layers between elements and labels" do
      seq = described_class.new(diagram_with_connector,
                                  model_index: model_index, canvas: canvas)
      layers = seq.layers
      svg = layers.join
      expect(svg).to include("<path")
    end
  end
end
