# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/parity"
require "xmi"

# Renders every diagram from examples/exports/*/model.xml and
# compares element counts against the corresponding reference SVG
# in examples/exports/*/images/.
#
# NOTE: examples/exports/basic.xmi is known to be stale relative to
# its reference SVGs (XMI/SVG drift — the SVGs were generated from
# a more complete XMI than the one committed here). The threshold
# reflects that some diagrams cannot match without fixture
# regeneration. See TODO.diagrams/04-rect-under-rendering.md for
# the underlying investigation.
RSpec.describe "EA sample exports regression", :sample_exports_regression do
  EXPORTS_DIR = File.expand_path("../../../examples/exports", __dir__)
  # The user's plateau fixtures live outside this repo (typically at
  # ~/src/mn/mn-samples-plateau/). Override via ENV if needed.
  PLATEAU_XMI = ENV.fetch("EA_PLATEAU_XMI",
                           File.expand_path("~/src/mn/mn-samples-plateau/sources/xmi/plateau_all_packages_export.xmi"))
  PLATEAU_REF_DIR = ENV.fetch("EA_PLATEAU_REF_DIR",
                                File.expand_path("~/src/mn/mn-samples-plateau/sources/001-mds/xmi-images"))

  before(:all) do
    skip "examples/exports/ not found at #{EXPORTS_DIR}" unless Dir.exist?(EXPORTS_DIR)
  end

  it "matches reference element counts within tolerance for most diagrams" do
    samples = all_samples
    skip "no sample diagrams found" if samples.empty?

    docs = {}
    samples.each do |s|
      docs[s[:name]] ||= begin
        root = Xmi::Sparx::Root.parse_xml(File.read(s[:model_xml]))
        Ea::Sources::Xmi::Adapter.new(root, s[:model_xml]).to_document
      end
    end

    within_tolerance = 0
    total = 0
    failures = []
    samples.each do |s|
      doc = docs[s[:name]]
      diagram = doc.diagrams.find { |d| d.id == s[:diagram_id] }
      next unless diagram

      ours = Ea::Svg::EaEmitter::Document.new(diagram, model_index: doc.index_by_id).render
      reference = File.read(s[:ref_svg])
      report = Ea::Svg::Parity::Checker.new(ours: ours, reference: reference).report

      total += 1
      # Looser threshold (40%) reflects XMI/SVG drift on the basic
      # samples. The plateau full-suite measurement (when fixtures
      # are available) is the authoritative parity check.
      if report.shape_delta_total <= 5
        within_tolerance += 1
      else
        failures << "#{s[:name]}/#{s[:diagram_id]}: shape_delta=#{report.shape_delta_total}"
      end
    end

    ratio = within_tolerance.to_f / total
    expect(ratio).to be > 0.4,
      "only #{within_tolerance}/#{total} within tolerance; first 5:\n" +
      failures.first(5).join("\n")
  end

  it "renders every diagram without raising" do
    samples = all_samples
    skip "no sample diagrams found" if samples.empty?

    docs = {}
    samples.each do |s|
      docs[s[:name]] ||= begin
        root = Xmi::Sparx::Root.parse_xml(File.read(s[:model_xml]))
        Ea::Sources::Xmi::Adapter.new(root, s[:model_xml]).to_document
      end
    end

    samples.each do |s|
      doc = docs[s[:name]]
      diagram = doc.diagrams.find { |d| d.id == s[:diagram_id] }
      expect(diagram).not_to be_nil, "diagram #{s[:diagram_id]} missing from #{s[:name]}"

      expect {
        Ea::Svg::EaEmitter::Document.new(diagram, model_index: doc.index_by_id).render
      }.not_to raise_error
    end
  end

  # Full plateau measurement against the 192 reference SVGs in
  # ~/src/mn/mn-samples-plateau. Skip if the references are not
  # available (the user-provided set is not checked in).
  describe "full plateau (192 reference SVGs)", :full_plateau do
    before(:all) do
      skip "plateau xmi not available at #{PLATEAU_XMI}" unless File.exist?(PLATEAU_XMI)
      skip "plateau refs not available at #{PLATEAU_REF_DIR}" unless Dir.exist?(PLATEAU_REF_DIR)
    end

    it "renders every plateau diagram without raising" do
      doc = build_plateau_doc
      doc.diagrams.each do |diagram|
        expect {
          Ea::Svg::EaEmitter::Document.new(diagram, model_index: doc.index_by_id).render
        }.not_to raise_error
      end
    end

    it "matches reference shape counts within tolerance for most diagrams" do
      doc = build_plateau_doc
      suite = Ea::Svg::Parity::Suite.new(doc, PLATEAU_REF_DIR).measure
      within = suite.per_diagram.count { |dr| dr.report.shape_delta_total <= 5 }
      total = suite.total
      ratio = within.to_f / total

      expect(ratio).to be > 0.6,
        "only #{within}/#{total} plateau diagrams within tolerance; " \
        "first 5 outliers:\n" +
        suite.outliers(shape_tolerance: 5).first(5).map(&:id).join("\n")
    end

    def build_plateau_doc
      root = Xmi::Sparx::Root.parse_xml(File.read(PLATEAU_XMI))
      Ea::Sources::Xmi::Adapter.new(root, PLATEAU_XMI).to_document
    end
  end

  def all_samples
    @all_samples ||= begin
      samples = []
      Dir.glob("#{EXPORTS_DIR}/*/model.xml").sort.each do |model_xml|
        name = File.basename(File.dirname(model_xml))
        images_dir = File.join(File.dirname(model_xml), "images")
        next unless Dir.exist?(images_dir)

        Dir.glob("#{images_dir}/*.svg").each do |ref_svg|
          diagram_id = File.basename(ref_svg, ".svg")
          samples << { name: name, model_xml: model_xml,
                        diagram_id: diagram_id, ref_svg: ref_svg }
        end
      end
      samples
    end
  end
end
