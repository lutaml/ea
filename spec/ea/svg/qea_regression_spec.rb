# frozen_string_literal: true

require "spec_helper"
require "ea"
require "xmi"
require "nokogiri"
require "ea/svg/parity"

# Renders diagrams directly from the QEA SQLite database and
# compares against EA's reference SVG output. No XMI middleman —
# the QEA is the canonical source, the SVGs are 100% derived from
# it, so any divergence is a real emitter bug.
RSpec.describe "EA QEA-direct regression", :qea_regression do
  QEA_PATH = File.expand_path("../../../examples/qea/20251010_current_plateau_v5.1.qmi",
                                __dir__)
  QEA_PATH_ALT = File.expand_path("../../../examples/qea/20251010_current_plateau_v5.1.qea",
                                    __dir__)
  # Constants defined inside RSpec.describe leak to top-level, so
  # use a unique name to avoid collision with visual_regression_spec.
  QEA_REF_DIR = File.expand_path("../../../examples/exports/20251010_current_plateau_v5/Images",
                                  __dir__).freeze

  before(:all) do
    skip "QEA not available at #{QEA_PATH} or #{QEA_PATH_ALT}" unless File.exist?(QEA_PATH_ALT)
    skip "ref dir not available at #{QEA_REF_DIR}" unless Dir.exist?(QEA_REF_DIR)
  end

  it "renders every diagram from the QEA without raising" do
    doc = build_qea_doc
    doc.diagrams.each do |diagram|
      expect {
        Ea::Svg::EaEmitter::Document.new(diagram, model_index: doc.index_by_id).render
      }.not_to raise_error
    end
  end

  it "matches reference shape counts within tolerance for most diagrams" do
    doc = build_qea_doc
    ref_index = build_ref_index(doc)

    within = 0
    total = 0
    failures = []
    doc.diagrams.each do |diagram|
      ref_path = ref_index[diagram.id]
      next unless ref_path

      ours = Ea::Svg::EaEmitter::Document.new(diagram, model_index: doc.index_by_id).render
      reference = File.read(ref_path)
      report = Ea::Svg::Parity::Checker.new(ours: ours, reference: reference).report

      total += 1
      if report.shape_delta_total <= 5
        within += 1
      else
        failures << "#{diagram.name}: shape_delta=#{report.shape_delta_total}"
      end
    end

    ratio = within.to_f / total
    expect(ratio).to be > 0.6,
      "only #{within}/#{total} within tolerance; first 5:\n" +
      failures.first(5).join("\n")
  end

  # ---- helpers ----

  def build_qea_doc
    path = File.exist?(QEA_PATH_ALT) ? QEA_PATH_ALT : QEA_PATH
    Ea::Sources::Qea::Adapter.from_path(path)
  end

  # Build { diagram_id => reference_svg_path } by converting QEA
  # GUIDs to the EAID_ filename format EA uses for SVG export.
  def build_ref_index(doc)
    doc.diagrams.filter_map.each_with_object({}) do |diagram, acc|
      eaid = Ea::Sources::Qea::IdNormalizer.to_eaid(diagram.id)
      path = File.join(QEA_REF_DIR, "#{eaid}.svg")
      next unless File.exist?(path)

      acc[diagram.id] = path
    end
  end
end
