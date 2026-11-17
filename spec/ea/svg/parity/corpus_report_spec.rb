# frozen_string_literal: true

require "spec_helper"
require "rake"
require "tmpdir"
require "yaml"
require "stringio"

RSpec.describe Ea::Svg::Parity::CorpusReport do # rubocop:disable Metrics/BlockLength
  let(:diagram) { Ea::Model::Diagram.new(id: "d1", name: "Changed", diagram_type: "logical") }
  let(:clean_diagram) { Ea::Model::Diagram.new(id: "d2", name: "Clean", diagram_type: "logical") }
  let(:document) do
    Ea::Model::Document.new(diagrams: [diagram, clean_diagram,
                                       Ea::Model::Diagram.new(id: "unreferenced")])
  end
  let(:reference) do
    <<~SVG
      <svg><g>
      <text x="0" y="0">anchor</text><text x="10" y="0">second anchor</text>
      <text x="20" y="0" style="font-family:Calibri;font-size:9pt;font-weight:400">label</text>
      <text x="30" y="0">missing</text>
      <rect x="10" y="10" width="100" height="50"/>
      <path d="M 10 100 L 100 100"/>
      </g></svg>
    SVG
  end
  let(:ours) do
    reference.sub('x="20"', 'x="24"').sub("Calibri", "Arial")
             .sub("9pt", "12pt").sub("400", "700").sub("missing", "extra")
             .sub('width="100"', 'width="101"').sub("M 10 100 L 100 100", "M 12 100 L 102 100")
  end
  let(:report_io) { StringIO.new }
  let(:output_path) { File.join(@ref_dir, "baseline.yml") }
  let(:report) { described_class.new(document: document, ref_dir: @ref_dir) }
  let(:counts) do
    {
      "moved_text" => 1, "missing_text" => 1, "extra_text" => 1,
      "wrong_font" => 1, "wrong_size" => 1, "wrong_weight" => 1,
      "missing_shapes" => 0, "extra_shapes" => 0, "shape_geometry" => 1,
      "source_endpoints" => 1, "target_endpoints" => 1, "arrowhead_tips" => 0
    }
  end

  around do |example|
    Dir.mktmpdir("parity-report") do |dir|
      @ref_dir = dir
      File.write(File.join(dir, "d1.svg"), reference)
      File.write(File.join(dir, "d2.svg"), reference)
      example.run
    end
  end

  before do
    [diagram, clean_diagram].each do |item|
      emitter = instance_double(Ea::Svg::EaEmitter::Document, render: item == diagram ? ours : reference)
      allow(Ea::Svg::EaEmitter::Document).to receive(:new)
        .with(item, model_index: document.index_by_id, document: document).and_return(emitter)
    end
  end

  it "writes safe-loadable YAML counts for every referenced diagram using Suite deltas" do
    result = report.run_baseline(output_path: output_path, io: report_io)

    expect(YAML.safe_load_file(output_path)).to eq(result)
    expected_rows = [
      { "id" => "d1", "name" => "Changed", "deltas" => counts },
      { "id" => "d2", "name" => "Clean", "deltas" => counts.transform_values { 0 } }
    ]
    expect(result.fetch("diagrams")).to eq(expected_rows)
    expect(result.fetch("totals")).to eq(counts)
    expect(report_io.string).to include("Diagrams: 2 (failures: 1)", "d1 (Changed)", "d2 (Clean)")
    counts.each { |key, count| expect(report_io.string).to include("#{key}=#{count}") }
  end

  it "writes an empty baseline when no diagrams have references" do
    File.delete(File.join(@ref_dir, "d1.svg"), File.join(@ref_dir, "d2.svg"))
    report.run_baseline(output_path: output_path, io: report_io)

    expect(YAML.safe_load_file(output_path)).to eq("diagrams" => [], "totals" => {})
    expect(report_io.string).to eq("Diagrams: 0 (failures: 0)\n")
  end

  it "preserves the legacy JSON report" do
    result = report.run(output_path: output_path)

    expect(JSON.parse(File.read(output_path))).to eq(JSON.parse(JSON.generate(result)))
    expect(result.fetch(:diagrams).map { |row| row.fetch(:id) }).to eq(%w[d1 d2])
    expect(result.fetch(:diagrams).first).to include(
      deltas: { extra_text: 1, missing_text: 1, moved_text: 1,
                wrong_font: 1, wrong_size: 1, wrong_weight: 1 },
      shapes: { matched: 2, missing: 0, extra: 0 }
    )
    expect(result.fetch(:totals)).to include(diagrams: 2, shapes: { matched: 4, missing: 0, extra: 0 })
  end

  context "with arrowhead drift and unmatched shapes" do
    let(:reference) do
      super().sub("</g>", '<polygon points="100,100 90,95 90,105"/><rect x="300" y="0"/></g>')
    end
    let(:ours) do
      super().sub("100,100 90,95 90,105", "102,100 92,95 92,105").sub('x="300"', 'x="700"')
    end

    it "includes missing and extra shapes and misplaced arrowhead tips in the baseline" do
      report.run_baseline(output_path: output_path, io: report_io)

      deltas = YAML.safe_load_file(output_path).fetch("diagrams").first.fetch("deltas")
      expect(deltas).to include("missing_shapes" => 1, "extra_shapes" => 1,
                                "shape_geometry" => 2, "arrowhead_tips" => 1)
    end
  end

  context "with rake tasks" do # rubocop:disable Metrics/BlockLength
    around do |example|
      previous = Rake.application
      Rake.application = Rake::Application.new
      load File.expand_path("../../../../lib/tasks/svg_bench.rake", __dir__)
      example.run
    ensure
      Rake.application = previous
    end

    let(:source) { File.join(@ref_dir, "source.xmi") }

    before do
      File.write(source, "source")
      allow(Ea::Svg::Parity::Source).to receive(:new).with(source)
                                                     .and_return(instance_double(Ea::Svg::Parity::Source,
                                                                                 load: document))
    end

    it "writes the baseline to the requested path from the parity_report task" do
      expect do
        Rake::Task["svg:parity_report"].invoke(source, @ref_dir, output_path)
      end.to output(/Diagrams: 2 \(failures: 1\)/).to_stdout

      expect(YAML.safe_load_file(output_path).fetch("diagrams").first.fetch("deltas")).to eq(counts)
    end

    it "defaults the output path to parity-baseline.yml" do
      Dir.chdir(@ref_dir) do
        expect do
          Rake::Task["svg:parity_report"].invoke(source, @ref_dir)
        end.to output(/Diagrams: 2/).to_stdout

        expect(YAML.safe_load_file("parity-baseline.yml").fetch("totals")).to eq(counts)
      end
    end

    it "requires source and reference arguments before writing a baseline" do
      expect do
        expect { Rake::Task["svg:parity_report"].invoke }.to raise_error(SystemExit)
      end.to output(/usage: rake svg:parity_report/).to_stderr
      expect(File.exist?(output_path)).to be(false)
    end

    it "preserves the bench output" do
      expected = <<~TEXT
        Source: #{source}
        Refs:   #{@ref_dir}
        Diagrams: 2 (matched: 2)
          rect    ours=     2 ref=     2 delta=    0 (0.0%)
          path    ours=     2 ref=     2 delta=    0 (0.0%)
          polygon ours=     0 ref=     0 delta=    0 (0.0%)
          text    ours=     8 ref=     8 delta=    0 (0.0%)
        Text overlap avg: 80.0%
      TEXT
      expect { Rake::Task["svg:bench"].invoke(source, @ref_dir) }.to output(expected).to_stdout
      expect(File.exist?(output_path)).to be(false)
    end

    it "preserves example output and finds exports without the QEA version suffix" do
      qea_dir = File.join(@ref_dir, "examples", "qea")
      images = File.join(@ref_dir, "examples", "exports", "sample", "Images")
      FileUtils.mkdir_p([qea_dir, images])
      qea = File.join(qea_dir, "sample.1.qea")
      File.write(qea, "source")
      File.write(File.join(qea_dir, "missing.qea"), "source")
      %w[d1 d2].each { |id| File.write(File.join(images, "#{id}.svg"), reference) }
      allow(File).to receive(:expand_path).and_call_original
      allow(File).to receive(:expand_path)
        .with("../..", File.expand_path("../../../../lib/tasks", __dir__)).and_return(@ref_dir)
      allow(Ea::Sources::Qea::Adapter).to receive(:from_path).with(qea).and_return(document)

      expected = <<~TEXT
        missing: SKIP (no exports/images directory)
        #{"sample.1".ljust(40)} 2/2 matched
          rect    ours=    2 ref=    2 delta=    0 (0.0%)
          path    ours=    2 ref=    2 delta=    0 (0.0%)
          polygon ours=    0 ref=    0 delta=    0 (0.0%)
          text    ours=    8 ref=    8 delta=    0 (0.0%)

      TEXT
      expect { Rake::Task["svg:examples"].invoke }.to output(expected).to_stdout
    end
  end
end
