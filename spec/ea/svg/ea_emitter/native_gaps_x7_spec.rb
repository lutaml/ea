# frozen_string_literal: true

require "spec_helper"

# Gaps measured against EA's native SVG export of the example models:
# name-direction triangles, tagged-value box growth and label paint order.
RSpec.describe "EA emitter native gaps (direction triangle, tagged growth, label order)" do
  # The framed render offsets native coordinates by the diagram margin.
  def frame_dx = 25
  def frame_dy = 30

  def render_xml(path, guid)
    document = Ea::Sources::Qea::Adapter.from_path(path)
    diagram = document.diagrams.find { |entry| entry.id.include?(guid) }
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                    document: document, frame: true).render
    Nokogiri::XML(svg).remove_namespaces!
  end

  def unframe(points)
    points.split.map(&:to_i).each_slice(2).flat_map { |x, y| [x - frame_dx, y - frame_dy] }.join(" ")
  end

  describe "basic.qea association with a directed name" do
    let(:xml) { render_xml("examples/qea/basic.qea", "2AAB709F") }

    it "draws the direction triangles at the native positions" do
      # native EAID_2AAB709F: <polygon points="42 162 39 152 45 152"> and
      # <polygon points="277 25 267 22 267 28">
      triangles = xml.xpath("//polygon").map { |p| unframe(p["points"]) }

      expect(triangles).to include("42 162 39 152 45 152", "277 25 267 22 267 28")
    end

    it "keeps the connector name texts" do
      expect(xml.xpath("//text").map(&:text)).to include("Association A", "Association B")
    end
  end

  describe "basic.qea association without a directed name (F32E5AFE)" do
    it "draws no three-point direction triangle" do
      polygons = render_xml("examples/qea/basic.qea", "F32E5AFE").xpath("//polygon")

      expect(polygons.map { |p| p["points"].split.size / 2 }).not_to include(3)
    end
  end

  describe "tagged-value growth (simple.qea 204F4ACC)" do
    it "draws the AcmeUmlClass box at the native height 85" do
      # native EAID_204F4ACC: <rect x="10" y="10" width="111" height="85">
      rects = render_xml("examples/qea/simple.qea", "204F4ACC").xpath("//rect")
      acme = rects.find { |r| r["x"].to_i == 10 + frame_dx && r["y"].to_i == 10 + frame_dy }

      expect(acme["height"]).to eq("85")
      expect(acme["width"]).to eq("111")
    end

    it "leaves boxes with no tagged overflow at their stored height" do
      rects = render_xml("examples/qea/simple.qea", "204F4ACC").xpath("//rect")
      heights = rects.select { |r| r["x"].to_i == 20 + frame_dx }.map { |r| r["height"] }

      expect(heights).to eq(["90"])
    end
  end

  describe "end-label paint order (basic.qea F32E5AFE)" do
    it "paints each connector as source role, name, target role like native" do
      texts = render_xml("examples/qea/basic.qea", "F32E5AFE").xpath("//text").map(&:text)

      # native EAID_F32E5AFE tail: +roleThree 0..3 +roleTwo 1 +roleOne 1
      expect(texts.last(6)).to eq(["+roleThree", "0..3", "+roleTwo", "1", "+roleOne", "1"])
    end
  end

  describe "label order with a named midpoint (basic.qea 2AAB709F)" do
    it "puts the source end texts before the midpoint name and the target end texts after" do
      texts = render_xml("examples/qea/basic.qea", "2AAB709F").xpath("//text").map(&:text)
      i = texts.index("Association A")

      expect(texts[i - 2, 5]).to eq(["+role a", "0..*", "Association A", "+role b", "0..*"])
    end
  end
end
