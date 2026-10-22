# frozen_string_literal: true

require "spec_helper"
require "ea"
require "fileutils"
require "tmpdir"
require "sqlite3"
require "nokogiri"

RSpec.describe "QEA diagram links and canvas on edited fixture copies" do
  let(:fixtures) { File.expand_path("../../../../examples/qea", __dir__) }

  def edited_copy(fixture, statement)
    path = File.join(Dir.mktmpdir("ea-x9"), "edited.qea")
    FileUtils.cp(File.join(fixtures, fixture), path)
    db = SQLite3::Database.new(path)
    db.execute(statement)
    db.close
    path
  end

  def load_document(path)
    Ea::Sources::Qea::Adapter.from_path(path)
  end

  def render(document, prefix, frame:)
    diagram = document.diagrams.find { |d| d.id.to_s.start_with?(prefix) }
    Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                              document: document, frame: frame).render
  end

  describe "a link whose connector no longer exists" do
    ["100000", "NULL", "''", "-1"].each do |value|
      it "loads the document and draws the other links (ConnectorID #{value})" do
        sql = "update t_diagramlinks set ConnectorID=#{value} " \
              "where rowid=(select min(rowid) from t_diagramlinks)"
        pristine = load_document(File.join(fixtures, "simple.qea"))
        document = load_document(edited_copy("simple.qea", sql))

        expect(document.diagrams.size).to eq(pristine.diagrams.size)
        expect(document.diagrams.sum { |d| d.connectors.size })
          .to be < pristine.diagrams.sum { |d| d.connectors.size }
        expect { document.diagrams.each { |d| render(document, d.id.to_s, frame: false) } }
          .not_to raise_error
      end
    end
  end

  describe "a framed canvas with a stored bend outside the elements" do
    def overflow(svg)
      doc = Nokogiri::XML(svg)
      _x, _y, width, height = doc.root["viewBox"].split.map(&:to_f)
      vertices = doc.xpath("//*[local-name()='path']").flat_map do |path|
        path["d"].to_s.scan(/(-?[\d.]+) (-?[\d.]+)/).map { |x, y| [x.to_f, y.to_f] }
      end
      vertices.reject { |x, y| x.between?(0, width) && y.between?(0, height) }
    end

    it "holds a bend left of every object" do
      path = edited_copy("basic.qea",
                         "update t_diagramlinks set Path='-300:-230;371:-230;' where rowid=1")
      expect(overflow(render(load_document(path), "F0F20BDF", frame: true))).to be_empty
    end

    it "holds a bend below every object" do
      path = edited_copy("basic.qea",
                         "update t_diagramlinks set Path='165:-900;371:-230;' where rowid=1")
      expect(overflow(render(load_document(path), "F0F20BDF", frame: true))).to be_empty
    end

    it "keeps the canvas of an unedited diagram" do
      document = load_document(File.join(fixtures, "basic.qea"))
      box = Nokogiri::XML(render(document, "F0F20BDF", frame: true)).root["viewBox"]
      expect(box).to eq("0 0 627 330")
    end
  end
end
