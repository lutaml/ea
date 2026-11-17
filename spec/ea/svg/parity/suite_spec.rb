# frozen_string_literal: true

require "spec_helper"
require "ea"
require "tmpdir"

RSpec.shared_context "suite delta report" do
  let(:reference) do
    <<~SVG
      <svg><g><text x="0" y="0" style="font-size:9pt">anchor</text>
      <rect x="10" y="10" width="100" height="50"/>
      <path d="M 10 100 L 100 100"/>
      <polygon points="100,100 90,95 90,105"/></g></svg>
    SVG
  end
  let(:ours) { reference }
  let(:report) do
    described_class.new(differ: Ea::Svg::Parity::Differ.new(ours: ours, reference: reference))
  end
end

RSpec.describe Ea::Svg::Parity::Suite::DiagramReport do
  include_context "suite delta report"

  it "has no deltas for identical primitives" do
    expect(report.delta_summary.values).to all(eq(0))
    expect(report).to be_clean
  end
end

RSpec.describe Ea::Svg::Parity::Suite::DiagramReport, "with changed geometry" do
  include_context "suite delta report"

  context "when measured" do
    let(:ours) { reference.sub('width="100"', 'width="101"') }

    it "uses the supplied epsilon without changing the measured report" do
      tolerances = Ea::Svg::Parity::Suite::Tolerances.new(epsilon: 1)
      expect(report.delta_summary[:shape_geometry]).to eq(1)
      expect(report).not_to be_clean
      expect(report.clean?(tolerances)).to be(true)
      suite = Ea::Svg::Parity::Suite::Report.new(per_diagram: [report])
      expect(suite.failures).to eq([report])
      expect(suite.failures(tolerances)).to be_empty
      expect(report).not_to be_clean
    end
  end
end

RSpec.describe Ea::Svg::Parity::Suite::DiagramReport, "with a changed connector source" do
  include_context "suite delta report"

  context "when measured" do
    let(:ours) { reference.sub("M 10 100", "M 12 100") }

    it "counts endpoint errors" do
      expect(report.delta_summary).to include(source_endpoints: 1, target_endpoints: 0)
      expect(report).not_to be_clean
    end
  end
end

RSpec.describe Ea::Svg::Parity::Suite::DiagramReport, "with a moved arrowhead" do
  include_context "suite delta report"

  context "when measured" do
    let(:ours) { reference.sub("100,100 90,95 90,105", "102,100 92,95 92,105") }

    it "counts misplaced tips" do
      expect(report.delta_summary[:arrowhead_tips]).to eq(1)
      expect(report).not_to be_clean
    end
  end
end

RSpec.describe Ea::Svg::Parity::Suite::DiagramReport, "with replaced text and shapes" do
  include_context "suite delta report"

  context "when measured" do
    let(:ours) { reference.sub("anchor", "extra").sub('x="10"', 'x="200"') }

    it "keeps missing and extra counts even when totals balance" do
      expect(report.delta_summary).to include(missing_text: 1, extra_text: 1, missing_shapes: 1, extra_shapes: 1)
      expect(report).not_to be_clean
    end
  end
end

RSpec.describe Ea::Svg::Parity::Suite::Tolerances do
  it "defaults to subpixel geometry tolerance" do
    expect(described_class.new.epsilon).to eq(0.51)
    expect(described_class.new).to be_frozen
  end

  it "rejects invalid geometry tolerances" do
    [-1, Float::INFINITY, Float::NAN].each do |epsilon|
      expect { described_class.new(epsilon: epsilon) }.to raise_error(ArgumentError)
    end
  end
end

RSpec.shared_context "rendered suite document" do
  let(:bounds) { Ea::Model::Bounds.new(x: 10, y: 10, width: 200, height: 100) }
  let(:element) do
    Ea::Model::DiagramElement.new(id: "de1", model_element_ref: "c1", bounds: bounds,
                                  image_bounds: bounds, font_family: "Calibri", font_size: 13)
  end
  let(:diagram) do
    Ea::Model::Diagram.new(id: "d1", name: "D", diagram_type: "logical", elements: [element])
  end
  let(:document) do
    Ea::Model::Document.new(classifiers: [Ea::Model::Klass.new(id: "c1", name: "Anchor")], diagrams: [diagram])
  end
  let(:svg) do
    Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document).render
  end
  let(:reference) { svg }
  let(:suite) { described_class.new(document, @ref_dir).measure }

  around do |example|
    Dir.mktmpdir("parity-suite") do |dir|
      @ref_dir = dir
      File.write(File.join(dir, "d1.svg"), reference)
      example.run
    end
  end
end

RSpec.describe Ea::Svg::Parity::Suite do
  include_context "rendered suite document"

  it "judges identical rendered SVGs clean and preserves count reporting" do
    expect(suite.total).to eq(1)
    expect(suite.per_diagram.first).to have_attributes(id: "d1", name: "D", type: "logical")
    expect(suite.per_diagram.first).to be_clean
    expect(suite.failures).to be_empty
    expect(suite.matched).to eq(1)
    expect(suite.text_overlap_avg).to eq(1.0)
    expect(suite.aggregate_shape_counts[:ours]).to eq(suite.aggregate_shape_counts[:reference])
  end
end

RSpec.describe Ea::Svg::Parity::Suite, "with a different reference font size" do
  include_context "rendered suite document"

  context "when measured" do
    let(:reference) { svg.sub(/font-size:[^;]+/, "font-size:99pt") }

    it "fails despite identical shape counts" do
      expect(reference).not_to eq(svg)
      expect(suite.matched).to eq(1)
      expect(suite.per_diagram.first.delta_summary[:wrong_size]).to eq(1)
      expect(suite.per_diagram.first).not_to be_clean
      expect(suite.failures).to eq(suite.per_diagram)
    end
  end
end

RSpec.describe Ea::Svg::Parity::Suite do
  include_context "rendered suite document"

  it "skips diagrams without references" do
    File.delete(File.join(@ref_dir, "d1.svg"))
    expect(suite.total).to eq(0)
    expect(suite.failures).to be_empty
  end
end

RSpec.describe Ea::Svg::Parity::Suite::Report do
  it "sums each primitive count independently for both sides" do
    ours = "<svg><g><rect/><rect/><path/><text>A</text></g></svg>"
    reference = "<svg><g><polygon/><text>A</text><text>B</text></g></svg>"
    checker = Ea::Svg::Parity::Checker.new(ours: ours, reference: reference)
    diagram = Ea::Svg::Parity::Suite::DiagramReport.new(report: checker.report)
    report = described_class.new(per_diagram: [diagram, diagram])

    expect(report.aggregate_shape_counts).to eq(
      ours: { rect: 4, polygon: 0, path: 2, text: 2 },
      reference: { rect: 0, polygon: 2, path: 0, text: 4 }
    )
  end

  it "returns zero counts for an empty suite" do
    expect(described_class.new(per_diagram: []).aggregate_shape_counts).to eq(
      ours: { rect: 0, polygon: 0, path: 0, text: 0 },
      reference: { rect: 0, polygon: 0, path: 0, text: 0 }
    )
  end
end
