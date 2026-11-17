# frozen_string_literal: true

require "spec_helper"
require "rake"
require "tmpdir"
require "yaml"
require "stringio"

RSpec.describe Ea::Svg::Parity::CorpusReport do # rubocop:disable Metrics/BlockLength
  let(:classifiers) do
    %w[anchor second label extra].map { |name| Ea::Model::Klass.new(id: name, name: name) }
  end
  let(:elements) do
    classifiers.each_with_index.map do |classifier, index|
      bounds = Ea::Model::Bounds.new(x: 10 + index * 200, y: 10, width: 120, height: 80)
      Ea::Model::DiagramElement.new(id: "de_#{classifier.id}", model_element_ref: classifier.id,
                                    bounds: bounds, image_bounds: bounds)
    end
  end
  let(:connector) do
    Ea::Model::DiagramConnector.new(
      id: "link", relationship_ref: "rel", source_element_ref: "anchor", target_element_ref: "second",
      connector_type: "Generalization",
      waypoints: [130, 210].map { |x| Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: 50)) }
    )
  end
  let(:diagram) do
    Ea::Model::Diagram.new(id: "d1", name: "Changed", diagram_type: "logical",
                           elements: elements, connectors: [connector])
  end
  let(:clean_diagram) do
    Ea::Model::Diagram.new(id: "d2", name: "Clean", diagram_type: "logical",
                           elements: elements, connectors: [connector])
  end
  let(:document) do
    Ea::Model::Document.new(
      classifiers: classifiers,
      relationships: [Ea::Model::Generalization.new(id: "rel", specific_id: "anchor", general_id: "second")],
      diagrams: [diagram, clean_diagram, Ea::Model::Diagram.new(id: "unreferenced")]
    )
  end
  let(:svg) do
    Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document).render
  end
  let(:clean_svg) do
    Ea::Svg::EaEmitter::Document.new(clean_diagram, model_index: document.index_by_id, document: document).render
  end
  let(:reference) do
    xml = Nokogiri::XML(svg)
    label = xml.at_css("text:contains('label')")
    label["x"] = (label["x"].to_f + 4).to_s
    label["style"] = label["style"].sub(/font-family:[^;]+/, "font-family:Arial")
                                   .sub(/font-size:[^;]+/, "font-size:99pt")
                                   .sub("font-weight:700", "font-weight:400")
    xml.at_css("text:contains('extra')").content = "missing"
    xml.at_css('rect[x="410"]')["width"] = "121"
    xml.at_css("path")["d"] = "M 132 50 L 212 50"
    xml.to_xml
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
      File.write(File.join(dir, "#{diagram.id}.svg"), reference)
      File.write(File.join(dir, "#{clean_diagram.id}.svg"), clean_svg)
      example.run
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
      shapes: { matched: 7, missing: 0, extra: 0 }
    )
    expect(result.fetch(:totals)).to include(diagrams: 2, shapes: { matched: 14, missing: 0, extra: 0 })
  end

  context "with arrowhead drift and unmatched shapes" do
    let(:reference) do
      super().sub("210 50 194 56 194 44", "212 50 196 56 196 44").sub('x="610"', 'x="1000"')
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

    let(:source) { fixtures_path("prefixed_names.xmi") }
    let(:document) { Ea::Svg::Parity::Source.new(source).load }
    let(:diagram) { document.diagrams.first }
    let(:clean_diagram) { document.diagrams.last }
    let(:reference) { svg.sub(/font-size:[^;]+/, "font-size:99pt") }
    let(:counts) { super().transform_values { 0 }.merge("wrong_size" => 1) }

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
          rect    ours=     4 ref=     4 delta=    0 (0.0%)
          path    ours=     2 ref=     2 delta=    0 (0.0%)
          polygon ours=     0 ref=     0 delta=    0 (0.0%)
          text    ours=     6 ref=     6 delta=    0 (0.0%)
        Text overlap avg: 100.0%
      TEXT
      expect { Rake::Task["svg:bench"].invoke(source, @ref_dir) }.to output(expected).to_stdout
      expect(File.exist?(output_path)).to be(false)
    end

    it "finds exports without the QEA version suffix using real directories" do
      exports = File.join(@ref_dir, "exports")
      images = File.join(exports, "sample", "Images")
      FileUtils.mkdir_p(images)

      found = Ea::Svg::Parity::BenchOutput.reference_dir(exports, "sample.1")
      expect(File.identical?(found, images)).to be(true)
      expect(Ea::Svg::Parity::BenchOutput.reference_dir(exports, "missing")).to be_nil
    end

    it "preserves example count formatting" do
      counts = { ours: { rect: 2, path: 1, polygon: 0, text: 4 },
                 reference: { rect: 2, path: 2, polygon: 0, text: 4 } }
      expected = <<~TEXT.gsub(/^/, "  ")
        rect    ours=    2 ref=    2 delta=    0 (0.0%)
        path    ours=    1 ref=    2 delta=   -1 (-50.0%)
        polygon ours=    0 ref=    0 delta=    0 (0.0%)
        text    ours=    4 ref=    4 delta=    0 (0.0%)
      TEXT
      expect { Ea::Svg::Parity::BenchOutput.shape_counts(counts, width: 5) }.to output(expected).to_stdout
    end
  end
end
