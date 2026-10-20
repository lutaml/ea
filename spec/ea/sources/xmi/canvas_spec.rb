# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI diagram canvas" do
  include XmiCanvasHelpers

  let(:xmi) { basic_canvas_document(Ea::Sources::Xmi::Adapter, "spec/fixtures/basic.xmi") }
  let(:qea) { basic_canvas_document(Ea::Sources::Qea::Adapter, "examples/qea/basic.qea") }

  {
    "F0F20BDF-C729-47F7-B6FC-25ED2C4609CA" => "0 0 627 330",
    "84352F1A-195B-411B-9552-5BFC40BF90B5" => "0 0 667 156",
    "BC008774-B539-4150-8174-B675989053D0" => "0 0 289 146"
  }.each do |diagram_id, view_box|
    it "renders #{diagram_id[0, 8]} with the canvas the QEA source gives" do
      expect(canvas_view_box(xmi, diagram_id)).to eq(view_box)
    end
  end

  it "stores the page size from the diagram style as the diagram bounds" do
    bounds = canvas_diagram(xmi, "F0F20BDF-C729-47F7-B6FC-25ED2C4609CA").bounds
    expect([bounds.x, bounds.y, bounds.width, bounds.height]).to eq([0, 0, 827, 1169])
  end

  it "keeps the logical element bounds" do
    package = canvas_diagram(xmi, "F0F20BDF-C729-47F7-B6FC-25ED2C4609CA").elements.map(&:bounds)
    expect(package.map { |b| [b.x, b.y, b.width, b.height] }).to contain_exactly(
      [512, 274, 130, 80], [306, 274, 130, 80], [100, 274, 130, 80], [306, 100, 130, 80]
    )
  end

  it "gives sampled diagrams the canvas the QEA source gives" do
    ids = %w[0EDEA6EF-4DC8-4979-BB80-28B1B9EBD1D4 D7AAC526-267E-45A0-A853-3207F02363F8]
    expect(ids.map { |id| canvas_view_box(xmi, id) }).to eq(ids.map { |id| canvas_view_box(qea, id) })
  end
end
