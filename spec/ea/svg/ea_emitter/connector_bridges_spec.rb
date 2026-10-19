# frozen_string_literal: true

require "spec_helper"

RSpec.shared_context "connector bridge diagram" do
  include ConnectorBridgesHelpers

  let(:winner) { bridge_connector("724", [[253, 343], [221, 343], [221, 644], [347, 644]]) }
  let(:lower) { bridge_connector("672", [[180, 485], [280, 485]]) }
  let(:other) { bridge_connector("721", [[180, 608], [280, 608]]) }
  let(:diagram) { bridge_diagram([winner, lower, other]) }
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "source-owner crossing bridges" do
  include_context "connector bridge diagram"

  it "bridges both native 724 crossings without changing the centerline model" do
    before = diagram.to_json
    expected = "M 253 343 L 221 343 L 221 479 A 6 6 180 0 0 221 491 " \
               "L 221 602 A 6 6 180 0 0 221 614 L 221 644 L 347 644"
    expect(bridge_paths(diagram)).to eq([expected, "M 180 485 L 280 485", "M 180 608 L 280 608"])
    expect(diagram.to_json).to eq(before)
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "source-owner crossing bridges" do
  include_context "connector bridge diagram"

  it "translates arc seats with the canvas" do
    canvas = Ea::Svg::EaEmitter::Canvas.new(min_x: 60, min_y: 70, width: 600, height: 800)
    expect(bridge_paths(diagram, canvas: canvas).first).to include(
      "L 196 449 A 6 6 180 0 0 196 461", "L 196 572 A 6 6 180 0 0 196 584"
    )
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "source-owner crossing bridges" do
  include_context "connector bridge diagram"

  it "keeps source priority through connector and style grouping order" do
    lower.connector_type = "Dependency"
    diagram.connectors = [lower, winner, other]
    [true, false].each do |grouped|
      paths = bridge_paths(diagram, grouped: grouped)
      expect(paths.count { |path| path.include?(" A ") }).to eq(1)
      expect(paths.find { |path| path.start_with?("M 253") }).to include("A 6 6 180 0 0 221 491")
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "source-owner crossing bridges" do
  include_context "connector bridge diagram"

  it "uses the higher source owner for both segment directions and orientations" do
    [
      [[[0, 50], [100, 50]], [[50, 0], [50, 100]], "M 0 50 L 44 50 A 6 6 180 0 0 56 50 L 100 50"],
      [[[100, 50], [0, 50]], [[50, 0], [50, 100]], "M 100 50 L 56 50 A 6 6 180 0 0 44 50 L 0 50"],
      [[[50, 100], [50, 0]], [[0, 50], [100, 50]], "M 50 100 L 50 56 A 6 6 180 0 0 50 44 L 50 0"]
    ].each do |first, second, expected|
      model = bridge_diagram([bridge_connector("a", first), bridge_connector("b", second)])
      expect(bridge_paths(model)).to eq([expected, "M #{second.first.join(" ")} L #{second.last.join(" ")}"])
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "source-owner crossing bridges" do
  include_context "connector bridge diagram"

  it "preserves paths with missing, tied or unresolved order keys" do
    [
      ->(model) { model.connectors.first.paint_order = nil },
      ->(model) { model.connectors.last.paint_order = [] },
      ->(model) { model.connectors.last.paint_order = [25] },
      ->(model) { model.connectors.first.paint_order = [9, 1] }
    ].each do |change|
      model = bridge_diagram([bridge_connector("a", [[50, 0], [50, 100]]),
                              bridge_connector("b", [[0, 50], [100, 50]])])
      change.call(model)
      expect(bridge_paths(model)).to eq(["M 50 0 L 50 100", "M 0 50 L 100 50"])
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "source-owner crossing bridges" do
  include_context "connector bridge diagram"

  it "preserves diagonals, collinear, shared ends, near bends and overlapping arc spans" do
    [
      [[[0, 0], [100, 100]]],
      [[[50, 20], [50, 80]]],
      [[[0, 0], [50, 0]]],
      [[[0, 5], [100, 5]]],
      [[[0, 50], [55, 50]]],
      [[[0, 50], [100, 50]], [[0, 60], [100, 60]]]
    ].each do |partners|
      connectors = [bridge_connector("a", [[50, 0], [50, 100]])]
      partners.each_with_index { |points, index| connectors << bridge_connector(index.to_s, points) }
      expect(bridge_paths(bridge_diagram(connectors)).first).to eq("M 50 0 L 50 100")
    end
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "source-owner crossing bridges" do
  include_context "connector bridge diagram"

  it "ignores hidden, implicit and unrenderable crossing partners" do
    [{ hidden: true }, { connector_type: "Nesting" }].each do |attributes|
      partner = bridge_connector("b", [[0, 50], [100, 50]], **attributes)
      model = bridge_diagram([bridge_connector("a", [[50, 0], [50, 100]]), partner])
      expect(bridge_paths(model)).to eq(["M 50 0 L 50 100"])
    end
    lower.waypoints = []
    diagram.connectors = [winner, lower]
    expect(bridge_paths(diagram)).to eq(["M 253 343 L 221 343 L 221 644 L 347 644"])
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "source-owner crossing bridges" do
  include_context "connector bridge diagram"

  it "preserves direct target-first bytes when there is no eligible bridge" do
    lower.hidden = true
    winner.waypoints = lower.waypoints
    winner.style = { direct: true }
    expect(bridge_paths(diagram).first).to eq("M 280 485 L 180 485 M 280 485")
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "native shared-stem preservation" do
  include ConnectorBridgesHelpers

  it "keeps native 672/730 collinear stems and shared target without bridges" do
    first = bridge_connector("672", [[262, 455], [129, 455], [129, 122], [452, 122]])
    second = bridge_connector("730", [[322, 578], [129, 578], [129, 122], [452, 122]])
    expect(bridge_paths(bridge_diagram([first, second], [9, 24]))).to eq([
                                                                           "M 262 455 L 129 455 L 129 122 L 452 122",
                                                                           "M 322 578 L 129 578 L 129 122 L 452 122"
                                                                         ])
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "resolved crossing routes" do
  include ConnectorBridgesHelpers

  it "finds crossings only after both routes redock and row slots adjust" do
    diagram, options = bridge_resolved_fixture
    before = diagram.to_json
    expect(bridge_paths(diagram)).to eq(["M 0 0 L 0 100", "M 0 150 L 100 150"])
    expect(bridge_paths(diagram, **options)).to eq([
                                                     "M 50 10 L 50 57 A 6 6 180 0 0 50 69 L 50 90", "M 10 63 L 90 63"
                                                   ])
    expect(diagram.to_json).to eq(before)
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "centerline marker preservation" do
  include ConnectorBridgesHelpers

  it "keeps resolved marker seats and waypoint objects while decorating the line" do
    diagram, options = bridge_resolved_fixture
    diagram.connectors.each { |connector| connector.connector_type = "Generalization" }
    geometry = diagram.connectors.flat_map(&:waypoints)
    markers = Ea::Svg::EaEmitter::Markers.new(diagram, **options).render
    expect(markers).to include('points="50 90 44 74 56 74"', 'points="90 63 74 69 74 57"')
    expect(bridge_paths(diagram, **options).first).to include("A 6 6 180 0 0 50 69")
    expect(Ea::Svg::EaEmitter::Markers.new(diagram, **options).render).to eq(markers)
    expect(diagram.connectors.flat_map(&:waypoints).zip(geometry).all? do |after, before|
      after.equal?(before)
    end).to be(true)
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "crossing priority direction" do
  include ConnectorBridgesHelpers

  it "decorates a later higher owner and permits a radius-sized endpoint clearance" do
    lower = bridge_connector("low", [[0, 50], [100, 50]])
    higher = bridge_connector("high", [[6, 0], [6, 100]])
    diagram = bridge_diagram([lower, higher], [9, 25])
    expected = ["M 0 50 L 100 50", "M 6 0 L 6 44 A 6 6 180 0 0 6 56 L 6 100"]
    expect(bridge_paths(diagram)).to eq(expected)
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "connector paint order" do
  include ConnectorBridgesHelpers

  let(:vertical) { bridge_connector("v", [[50, 0], [50, 100]]) }
  let(:horizontal) { bridge_connector("h", [[0, 50], [100, 50]]) }
  let(:arc) { "M 0 50 L 44 50 A 6 6 180 0 0 56 50 L 100 50" }

  it "bridges over the connector with the later paint order despite owner z-order" do
    vertical.paint_order = [10, 629]
    horizontal.paint_order = [20, 630]
    diagram = bridge_diagram([vertical, horizontal], [99, 1])
    expect(bridge_paths(diagram)).to eq(["M 50 0 L 50 100", arc])
  end

  it "leaves identical keys unbridged" do
    vertical.paint_order = [10, 629]
    horizontal.paint_order = [10, 629]
    expect(bridge_paths(bridge_diagram([vertical, horizontal]))).to eq(["M 50 0 L 50 100", "M 0 50 L 100 50"])
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "unresolved paint order" do
  include ConnectorBridgesHelpers

  it "fails closed for an empty key without falling back to owner z-order" do
    vertical = bridge_connector("v", [[50, 0], [50, 100]], paint_order: [])
    horizontal = bridge_connector("h", [[0, 50], [100, 50]], paint_order: [20, 630])
    paths = bridge_paths(bridge_diagram([vertical, horizontal], [99, 1]))
    expect(paths).to eq(["M 50 0 L 50 100", "M 0 50 L 100 50"])
    horizontal.paint_order = []
    vertical.paint_order = [30, 631]
    expect(bridge_paths(bridge_diagram([vertical, horizontal], [1, 99]))).to eq(paths)
  end

  it "defaults to nil and round-trips through JSON" do
    expect(Ea::Model::DiagramConnector.new(id: "a").paint_order).to be_nil
    restored = Ea::Model::DiagramConnector.from_json(
      Ea::Model::DiagramConnector.new(id: "a", paint_order: [583, 95]).to_json
    )
    expect(restored.paint_order).to eq([583, 95])
  end
end

RSpec.describe Ea::Svg::EaEmitter::Connectors, "shared start placement" do
  include ConnectorBridgesHelpers

  it "makes no carrier decision between connectors leaving one placement" do
    vertical = bridge_connector("v", [[50, 0], [50, 100]], paint_order: [10, 628])
    horizontal = bridge_connector("h", [[0, 50], [100, 50]], paint_order: [10, 629])
    vertical.source_element_ref = horizontal.source_element_ref = "shared"
    expect(bridge_paths(bridge_diagram([vertical, horizontal]))).to eq(["M 50 0 L 50 100", "M 0 50 L 100 50"])
    horizontal.source_element_ref = "other"
    expect(bridge_paths(bridge_diagram([vertical, horizontal])).last).to include(" A ")
  end
end
