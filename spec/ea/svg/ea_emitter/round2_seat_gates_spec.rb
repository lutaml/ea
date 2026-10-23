# frozen_string_literal: true

require "spec_helper"
require "sqlite3"
require "tmpdir"
require "fileutils"

# Seat and direction-triangle gates on basic.qea, driven by edited copies.
RSpec.describe "EA emitter seat widths and direction gate" do
  let(:source) { File.expand_path("../../../../examples/qea/basic.qea", __dir__) }

  def render(db_path, guid)
    document = Ea::Sources::Qea::Adapter.from_path(db_path)
    diagram = document.diagrams.find { |entry| entry.id.to_s.upcase.start_with?(guid) }
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document).render
    Nokogiri::XML(svg).remove_namespaces!
  end

  def edited_copy(dir, sql)
    path = File.join(dir, "edited.qea")
    FileUtils.cp(source, path)
    db = SQLite3::Database.new(path)
    db.execute(sql)
    db.close
    path
  end

  describe "plain leftward source role (basic 6D0349D5 role b, connector 67)" do
    # Cambria 7pt has no metrics for these glyphs; the seat must still apply
    # with the width the renderer prints, so the role stays on y=35.
    ["role b", "role J", "role 7", "role b,", "role ?"].each do |role|
      it "seats #{role.inspect} 7px above the corner" do
        Dir.mktmpdir("ea-round2").then do |dir|
          path = edited_copy(dir, "update t_connector set SourceRole='#{role}' where Connector_ID=67")
          text = render(path, "6D0349D5").css("text").find { |node| node.text == "+#{role}" }

          expect(text["y"]).to eq("35.00")
        end
      end
    end
  end

  describe "name-direction triangle (basic 2AAB709F, connectors 29 and 30)" do
    def triangles(path)
      render(path, "2AAB709F").xpath("//polygon").select { |p| p["points"].split.size == 6 }
    end

    it "draws the measured triangles for Direction Unspecified" do
      expect(triangles(source).size).to eq(2)
    end

    ["Job 7", "role J"].each do |name|
      it "still draws the triangle beside the unmeasured name #{name.inspect}" do
        Dir.mktmpdir("ea-round2").then do |dir|
          path = edited_copy(dir, "update t_connector set Name='#{name}' where Connector_ID = 30")
          xml = render(path, "2AAB709F")
          text = xml.css("text").find { |node| node.text == name }
          tips = triangles(path).map { |p| p["points"].split.map(&:to_f).first(2) }
          printed = text["x"].to_f + text["textLength"].to_f
          seats = [printed + 16, text["x"].to_f + (text["textLength"].to_f / 2)]
          near = tips.any? { |x, _| seats.any? { |v| (x - v).abs <= 1 } }

          expect(near).to be(true)
        end
      end
    end

    ["Bi-Directional", "Destination -> Source", "Source -> Destination"].each do |direction|
      it "draws no triangle for #{direction}" do
        Dir.mktmpdir("ea-round2").then do |dir|
          path = edited_copy(dir, "update t_connector set Direction='#{direction}' where Connector_ID in (29, 30)")

          expect(triangles(path)).to be_empty
        end
      end
    end
  end
end
