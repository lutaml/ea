# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe Ea::Svg::EaEmitter::ConnectorRedock do # rubocop:disable Metrics/BlockLength
  include ConnectorRedockHelpers

  it "clips width-2 generalization and aggregation lines and markers against the stroke outline" do # rubocop:disable Metrics/BlockLength
    [
      [{}, "M 20 99 L 20 41", "20 41 26 52 14 52"],
      [{ source: [0, 0, 40, 40], target: [0, 100, 40, 40], anchors: [[20, 20], [20, 120]] },
       "M 20 41 L 20 99", "20 99 14 88 26 88"],
      [{ source: [100, 100, 40, 40], anchors: [[120, 120], [20, 20]] },
       "M 99 99 L 41 41", "41 41 53.02 44.54 44.54 53.02"],
      [{ anchors: [[25, 120], [25, 20]] }, "M 25 99 L 25 41", "25 41 31 52 19 52"],
      [{ anchors: nil }, "M 20 99 L 20 41", "20 41 26 52 14 52"],
      [{ anchors: [nil, [20, 20]] }, "M 20 99 L 20 41", "20 41 26 52 14 52"],
      [{ anchors: [[20, 120], nil] }, "M 20 99 L 20 41", "20 41 26 52 14 52"],
      [{ type: "Aggregation" }, "M 20 99 L 20 41", "20 99 15 89 20 79 25 89"],
      [{ source: [0, 39, 40, 40], anchors: [[20, 59], [20, 20]] },
       "M 20 38 L 20 41", "20 41 14 30 26 30"],
      [{ source: [39, 39, 40, 40], anchors: [[59, 59], [20, 20]] },
       "M 38 38 L 41 41", "41 41 28.98 37.46 37.46 28.98"]
    ].each do |parameters, path, marker|
      expect(redock_output(redock_fixture(parameters))).to eq([[path], [marker]]), parameters.inspect
    end
  end

  it "preserves existing clipping outside the explicit type, width and positive-dimension scope" do # rubocop:disable Metrics/BlockLength
    parameters = ["0", "1", "3", nil, "2.0", 2].map { |width| { width: width } }
    parameters += [
      { type: "Association" }, { type: "Dependency" },
      { source: [0, 100, 0, 40] }, { source: [0, 100, 40, 0] },
      { target: [0, 0, 0, 40] }, { target: [0, 0, 40, 0] },
      { source: [0, 100, -1, 40] }, { target: [0, 0, 40, -1] },
      { source: nil }, { target: nil }
    ]
    parameters.each do |input|
      expect(redock_output(redock_fixture(input))).to eq(
        redock_output(redock_fixture(input.merge(width: "0")))
      ), input.inspect
    end
    [nil, { "lwidth" => "2" }].each do |style|
      fixture = redock_fixture
      fixture[:diagram].connectors.first.style = style
      expect(redock_output(fixture)).to eq([["M 20 100 L 20 40"], ["20 40 26 51 14 51"]])
    end
    expect(redock_output(redock_fixture(type: "Association"))).to eq(
      [["M 20 100 L 20 40"], ["M 26 55 L 20 40 L 14 55"]]
    )
    [
      [{ type: "Association", source: [115, 527, 161, 80], target: [122, 361, 146, 80],
         anchors: [[195, 567], [195, 401]] }, "M 195 527 L 195 441"],
      [{ width: "0", source: [532, 453, 202, 125], target: [562, 279, 142, 70],
         anchors: [[636, 512], [636, 311]] }, "M 636 453 L 636 349"],
      [{ width: "0", source: [562, 279, 142, 70], target: [468, 55, 330, 142],
         anchors: [[633, 314], [633, 126]] }, "M 633 279 L 633 197"]
    ].each do |input, path|
      expect(redock_output(redock_fixture(input)).first).to eq([path]), input.inspect
    end
  end

  it "retains stored routing when relationship, bounds or two-end resolution is unavailable" do
    [
      ->(fixture) { fixture[:drawn_bounds] = nil },
      ->(fixture) { fixture[:model_index] = nil },
      ->(fixture) { fixture[:model_index].clear },
      ->(fixture) { fixture[:model_index]["r"].general_id = nil },
      ->(fixture) { fixture[:model_index]["r"].general_id = "s" }
    ].each do |change|
      fixture = redock_fixture
      change.call(fixture)
      expect(redock_output(fixture).first).to eq(["M 20 100 L 20 40"])
    end
    fixture = redock_fixture(points: [[20, 100], [30, 70], [20, 40]])
    expect(redock_output(fixture).first).to eq(["M 20 100 L 30 70 L 20 40"])
  end

  it "preserves original routes and markers when stroke clipping would collapse or reverse them" do
    [[0, 41], [0, 42], [0, 40], [41, 41], [42, 42], [40, 40]].each do |x, y|
      parameters = { source: [x, y, 40, 40], anchors: [[x + 20, y + 20], [20, 20]] }
      expect(redock_output(redock_fixture(parameters))).to eq(
        redock_output(redock_fixture(parameters.merge(width: "0")))
      ), parameters.inspect
    end
  end

  it "preserves final routes and markers when row-slot seating would collapse the stroke outline" do
    parameters = [0, 1, 39, 40].flat_map do |x|
      [
        { source: [0, 55, 40, 40], anchors: [[x, 75], [x, 20]],
          dividers: { "s" => 0, "t" => 40 } },
        { source: [0, 0, 40, 40], target: [0, 55, 40, 40], anchors: [[x, 20], [x, 75]],
          dividers: { "s" => 40, "t" => 0 } }
      ]
    end
    parameters.each do |input|
      expect(redock_output(redock_fixture(input))).to eq(
        redock_output(redock_fixture(input.merge(width: "0")))
      ), input.inspect
    end
  end

  it "retains existing row-slot behavior for caller-supplied pairs" do
    fixture = redock_fixture(source: [0, 55, 40, 40], anchors: [[0, 75], [0, 20]],
                             dividers: { "s" => 0, "t" => 40 })
    pairs = [[0, 53], [0, 40]]
    expect(described_class.row_slot_adjust(
             pairs, fixture[:diagram].connectors.first, fixture[:diagram],
             fixture[:model_index], fixture[:drawn_bounds], fixture[:divider_y_by_ref]
           )).to eq([[0, 53], [0, 53]])
  end

  it "applies row-slot adjustment against the original drawn rectangle and divider" do
    result = redock_output(redock_fixture(
                             target: [100, 0, 40, 40], anchors: [[20, 120], [120, 20]],
                             dividers: { "s" => 100, "t" => 10 }
                           ))
    expect(result).to eq([["M 41 112 L 99 41"], ["99 41 96.69 53.31 87.39 45.72"]])
  end

  it "preserves the map, rectangles and connector geometry through both consumers" do
    fixture = redock_fixture(anchors: [[25, 120], [25, 20]])
    connector = fixture[:diagram].connectors.first
    connector.source_port = Ea::Model::Point.new(x: 25, y: 100)
    connector.target_port = Ea::Model::Point.new(x: 25, y: 40)
    bounds = fixture[:drawn_bounds]
    rectangles = bounds.dup
    before_bounds = bounds.transform_values { |box| [box.x, box.y, box.width, box.height] }
    geometry = [connector.source_anchor, connector.target_anchor, connector.source_port,
                connector.target_port, *connector.waypoints, *connector.waypoints.map(&:position)]
    before_geometry = geometry.map(&:to_json)
    expect(redock_output(fixture)).to eq([["M 25 99 L 25 41"], ["25 41 31 52 19 52"]])
    expect(fixture[:drawn_bounds]).to equal(bounds)
    expect(bounds.keys).to eq(rectangles.keys)
    rectangles.each { |key, box| expect(bounds[key]).to equal(box) }
    expect(bounds.transform_values { |box| [box.x, box.y, box.width, box.height] }).to eq(before_bounds)
    after_geometry = [connector.source_anchor, connector.target_anchor, connector.source_port,
                      connector.target_port, *connector.waypoints, *connector.waypoints.map(&:position)]
    after_geometry.zip(geometry).each { |after, before| expect(after).to equal(before) }
    expect(after_geometry.map(&:to_json)).to eq(before_geometry)
  end
end
