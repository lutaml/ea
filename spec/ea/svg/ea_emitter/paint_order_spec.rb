# frozen_string_literal: true

require "spec_helper"

# EA paints placements by descending Sequence and connectors by their
# stored paint key, each line directly followed by its own heads.
RSpec.describe "EA paint order" do # rubocop:disable Metrics/BlockLength
  def waypoints(*points)
    points.map { |x, y| Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y)) }
  end

  def placement(ref, z_order, x)
    Ea::Model::DiagramElement.new(
      model_element_ref: ref, z_order: z_order,
      bounds: Ea::Model::Bounds.new(x: x, y: 0, width: 50, height: 40)
    )
  end

  def generalization(ref, paint_order, y)
    Ea::Model::DiagramConnector.new(
      relationship_ref: ref, connector_type: "Generalization", paint_order: paint_order,
      waypoints: waypoints([100, y], [300, y])
    )
  end

  def svg_for(diagram, index)
    Nokogiri::XML(Ea::Svg::EaEmitter::Document.new(diagram, model_index: index, content_anchor: false).render)
  end

  let(:index) do
    { "a" => Ea::Model::Klass.new(id: "a", name: "Alpha"), "b" => Ea::Model::Klass.new(id: "b", name: "Beta"),
      "r1" => Ea::Model::Generalization.new(id: "r1", specific_id: "a", general_id: "b"),
      "r2" => Ea::Model::Generalization.new(id: "r2", specific_id: "b", general_id: "a") }
  end

  it "paints placements by descending Sequence" do
    diagram = Ea::Model::Diagram.new(elements: [placement("a", 1, 10), placement("b", 2, 200)])
    xs = svg_for(diagram, index).xpath("//*[local-name()='rect'][@height='40']").map { |rect| rect["x"].to_i }

    expect(xs).to eq([200, 10].map { |x| x + xs.min - 10 })
  end

  it "keeps the stored order of placements sharing a Sequence" do
    diagram = Ea::Model::Diagram.new(elements: [placement("a", 3, 10), placement("b", 3, 200)])
    xs = svg_for(diagram, index).xpath("//*[local-name()='rect'][@height='40']").map { |rect| rect["x"].to_i }

    expect(xs).to eq([10, 200].map { |x| x + xs.min - 10 })
  end

  it "follows each connector line with its own head, in stored paint order" do
    diagram = Ea::Model::Diagram.new(
      elements: [placement("a", 1, 10), placement("b", 2, 200)],
      connectors: [generalization("r1", [9, 1], 60), generalization("r2", [3, 2], 90)]
    )
    shapes = svg_for(diagram, index).xpath("//*[local-name()='path' or local-name()='polygon']")
    lines = shapes.select { |node| node.name == "path" }

    expect(shapes.map(&:name)).to eq(%w[path polygon path polygon])
    expect(lines.map { |node| node["d"][/M (\d+)/, 1].to_i }).to eq([225, 85])
  end

  it "paints connectors without a stored key after the keyed ones" do
    phantom = generalization("r1", nil, 60)
    keyed = generalization("r2", [1, 1], 90)
    diagram = Ea::Model::Diagram.new(elements: [placement("a", 1, 10), placement("b", 2, 200)],
                                     connectors: [phantom, keyed])
    lines = svg_for(diagram, index).xpath("//*[local-name()='path']")

    expect(lines.map { |node| node["d"][/M (\d+)/, 1].to_i }).to eq([225, 85])
  end

  it "paints a placement with no Sequence first, as before the descending order" do
    diagram = Ea::Model::Diagram.new(elements: [placement("a", 2, 10), placement("b", nil, 200)])
    xs = svg_for(diagram, index).xpath("//*[local-name()='rect'][@height='40']").map { |rect| rect["x"].to_i }

    expect(xs).to eq([200, 10].map { |x| x + xs.min - 10 })
  end

  it "paints a missing Sequence first, then the positive ones, then a Sequence of 0" do
    diagram = Ea::Model::Diagram.new(elements: [placement("a", 0, 10), placement("b", nil, 200),
                                                placement("a", 3, 400)])
    xs = svg_for(diagram, index).xpath("//*[local-name()='rect'][@height='40']").map { |rect| rect["x"].to_i }

    expect(xs).to eq([200, 400, 10].map { |x| x + xs.min - 10 })
  end

  it "treats a paint key with a nil part as unresolved instead of failing to compare" do
    unresolved = generalization("r1", [nil, 1], 60)
    keyed = generalization("r2", [1, 1], 90)
    diagram = Ea::Model::Diagram.new(elements: [placement("a", 1, 10), placement("b", 2, 200)],
                                     connectors: [unresolved, keyed])
    lines = svg_for(diagram, index).xpath("//*[local-name()='path']")

    expect(lines.map { |node| node["d"][/M (\d+)/, 1].to_i }).to eq([225, 85])
  end
end
