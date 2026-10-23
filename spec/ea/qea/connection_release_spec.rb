# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

# rubocop:disable Metrics/BlockLength
RSpec.describe "QEA database connection release" do
  let(:dir) { Dir.mktmpdir }
  let(:copy) { File.join(dir, "copy.qea") }

  before { FileUtils.cp(File.expand_path("../../fixtures/basic.qea", __dir__), copy) }

  after { FileUtils.rm_rf(dir) }

  def open_handles_for(path)
    # No GC.start: a collected handle is closed by its finalizer, which
    # would hide a missing explicit close.
    ObjectSpace.each_object(SQLite3::Database).reject(&:closed?).select do |db|
      db.filename.to_s.end_with?(File.basename(path))
    end
  end

  it "closes the handle after Ea.parse" do
    database = Ea.parse(copy)

    expect(open_handles_for(copy)).to be_empty
    expect(database.objects).not_to be_empty
  end

  it "closes the handle after Adapter.from_path and render" do
    doc = Ea::Sources::Qea::Adapter.from_path(copy)
    diagram = doc.diagrams.first
    Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: doc.index_by_id, document: doc
    ).render

    expect(open_handles_for(copy)).to be_empty
  end

  it "allows deleting the file right after loading" do
    database = Ea.parse(copy)

    expect { File.delete(copy) }.not_to raise_error
    expect(File.exist?(copy)).to be(false)
    expect(database.objects).not_to be_empty
  end

  it "keeps close_connection safe after the loader already closed it" do
    database = Ea.parse(copy)

    expect { 2.times { database.close_connection } }.not_to raise_error
  end
end
# rubocop:enable Metrics/BlockLength
