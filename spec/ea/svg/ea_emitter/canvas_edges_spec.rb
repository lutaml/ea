# frozen_string_literal: true

require "spec_helper"
require "ea"
require "nokogiri"
require "open3"
require "tmpdir"

# Content drawn right of / below / left of the stored element rects must
# stay on the canvas, and a framed export of an empty diagram must hold
# its own name tab.
RSpec.describe "canvas edges" do
  def model(name:, bounds:, attributes: 0)
    properties = Array.new(attributes) do |i|
      Ea::Model::Property.new(id: "a#{i}", name: "attr#{i}", type_name: "String",
                              owner_id: "c1")
    end
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      packages: [Ea::Model::Package.new(id: "p1", name: "Root")],
      classifiers: [Ea::Model::Klass.new(id: "c1", name: name, package_id: "p1",
                                         properties: properties)],
      diagrams: [Ea::Model::Diagram.new(
        id: "d1", name: "Edges", diagram_type: "logical",
        elements: [Ea::Model::DiagramElement.new(
          id: "de1", model_element_ref: "c1", bounds: bounds, image_bounds: bounds
        )]
      )]
    )
  end

  def render(document, **options)
    diagram = document.diagrams.first
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, **options
    ).render
    xml = Nokogiri::XML(svg)
    xml.remove_namespaces!
    [xml, xml.root["viewBox"].split.map(&:to_f)]
  end

  def right_edges(xml)
    xml.xpath("//text").map { |t| t["x"].to_f + t["textLength"].to_f }
  end

  def bottoms(xml, view_box)
    xml.xpath("//rect").filter_map do |r|
      next if r["width"].to_f >= view_box[2] - 1 && r["height"].to_f >= view_box[3] - 1

      r["y"].to_f + r["height"].to_f
    end
  end

  describe "drawn text wider than its box (default export)" do
    let(:bounds) { Ea::Model::Bounds.new(x: 100, y: 10, width: 30, height: 40) }
    let(:name) { "AbstractBuildingSubdivisionWithALongName" }

    it "keeps the whole name inside the viewBox" do
      xml, view_box = render(model(name: name, bounds: bounds))
      expect(right_edges(xml).max).to be <= view_box[2]
    end

    it "leaves the canvas of a name that fits unchanged" do
      short = Ea::Model::Bounds.new(x: 100, y: 10, width: 200, height: 40)
      _xml, view_box = render(model(name: "Fits", bounds: short))
      expect(view_box[2]).to eq(short.width + 10 + 10)
    end
  end

  describe "CanvasAnchor.measured" do
    it "extends the right and bottom edges to drawn text plus the text margin" do
      canvas = Ea::Svg::EaEmitter::CanvasAnchor.measured(
        [0, 0, 50, 20], [0, 0, 200.2, 90.5], nil, bottom: 31
      )
      expect([canvas.width, canvas.height]).to eq([211, 101])
    end

    it "keeps the shape margins when the text sits inside them" do
      canvas = Ea::Svg::EaEmitter::CanvasAnchor.measured(
        [0, 0, 50, 20], [0, 0, 20, 10], nil, bottom: 31
      )
      expect([canvas.width, canvas.height]).to eq([65, 56])
    end
  end

  describe "framed export" do
    it "holds a classifier grown below its stored rect" do
      bounds = Ea::Model::Bounds.new(x: 10, y: 10, width: 100, height: 40)
      xml, view_box = render(model(name: "Grown", bounds: bounds, attributes: 6),
                             frame: true)
      expect(bottoms(xml, view_box).max).to be <= view_box[3]
    end

    it "keeps the canvas of a classifier that fits" do
      bounds = Ea::Model::Bounds.new(x: 10, y: 10, width: 200, height: 100)
      _xml, view_box = render(model(name: "Fits", bounds: bounds, attributes: 1),
                              frame: true)
      expect(view_box).to eq([0, 0, 285, 176])
    end

    it "holds content left of the model origin" do
      bounds = Ea::Model::Bounds.new(x: -100, y: 10, width: 100, height: 50)
      xml, = render(model(name: "Left", bounds: bounds, attributes: 3), frame: true)
      lefts = xml.xpath("//rect").map { |r| r["x"].to_f } +
              xml.xpath("//text").map { |t| t["x"].to_f }
      expect(lefts.min).to be >= 0
    end

    it "sizes an empty diagram to hold its name tab" do
      empty = Ea::Model::Diagram.new(id: "e", name: "Empty", diagram_type: "logical")
      svg = Ea::Svg::EaEmitter::Document.new(empty, model_index: {}, frame: true).render
      width = svg[/viewBox="0 0 ([\d.]+)/, 1].to_f
      tab_right = svg[/<polygon points="([^"]*)"/, 1].split.map(&:to_f).each_slice(2).map(&:first).max
      expect(width).to be > tab_right
    end
  end

  describe "ea diagrams extract without --output" do
    it "writes the SVG next to the source without preloaded fileutils" do
      Dir.mktmpdir do |dir|
        FileUtils.cp(fixtures_path("basic.qea"), dir)
        script = <<~RUBY
          require "ea"
          require "ea/cli"
          Ea::Cli::Command::Diagrams.new(action: "extract",
            file: #{File.join(dir, "basic.qea").inspect}, name: "Domain Model").call
        RUBY
        out, status = Open3.capture2e(RbConfig.ruby, "-Ilib", "-e", script)
        expect(status.success?).to be(true), out
        expect(Dir[File.join(dir, "*.svg")]).not_to be_empty
      end
    end
  end
end
