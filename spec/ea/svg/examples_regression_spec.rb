# frozen_string_literal: true

require "spec_helper"
require "ea"
require "xmi"
require "nokogiri"
require "ea/svg/parity"

# Cross-example regression coverage. Each QEA in examples/qea has a
# matching export directory in examples/exports with reference SVGs.
# This spec exercises every (QEA, model.xml, Images) triple to catch
# regressions across the full fixture set, not just the plateau model.
module ExamplesRegressionHelpers
  ROOT = File.expand_path("../../..", __dir__)

  EXAMPLES = [
    { name: "plateau", qea: "20251010_current_plateau_v5.1.qea",
      export: "20251010_current_plateau_v5" },
    { name: "arcgis", qea: "ArcGISWorkspace_template.qea",
      export: "ArcGISWorkspace_template" },
    { name: "basic", qea: "basic.qea", export: "basic" },
    { name: "simple", qea: "simple.qea", export: "simple" },
    { name: "test", qea: "test.qea", export: "test" }
  ].freeze

  module_function

  def qea_path(filename)
    File.join(ROOT, "examples", "qea", filename)
  end

  def model_xml_path(export_name)
    File.join(ROOT, "examples", "exports", export_name, "model.xml")
  end

  def images_dir(export_name)
    File.join(ROOT, "examples", "exports", export_name, "Images")
  end
end

RSpec.describe "EA examples regression", :examples_regression do
  ExamplesRegressionHelpers::EXAMPLES.each do |ex|
    next unless File.exist?(ExamplesRegressionHelpers.qea_path(ex[:qea]))

    describe ex[:name] do
      include ExamplesRegressionHelpers

      let(:qea_doc) do
        Ea::Sources::Qea::Adapter.from_path(qea_path(ex[:qea]))
      end

      it "parses without raising" do
        expect { qea_doc }.not_to raise_error
      end

      it "parses at least one diagram" do
        skip "no diagrams in #{ex[:name]} QEA" if qea_doc.diagrams.empty?
        expect(qea_doc.diagrams.size).to be >= 1
      end

      it "parses the XMI model.xml without raising" do
        path = model_xml_path(ex[:export])
        skip "no model.xml for #{ex[:name]}" unless File.exist?(path)

        expect {
          Ea::Sources::Xmi::Adapter.from_path(path)
        }.not_to raise_error
      end

      it "renders every diagram with a reference SVG without raising" do
        images = images_dir(ex[:export])
        skip "no reference images for #{ex[:name]}" unless Dir.exist?(images)
        qea_doc.diagrams.each do |diagram|
          eaid = Ea::Sources::Qea::IdNormalizer.to_eaid(diagram.id)
          ref_path = File.join(images, "#{eaid}.svg")
          next unless File.exist?(ref_path)

          expect {
            Ea::Svg::EaEmitter::Document.new(diagram,
                                              model_index: qea_doc.index_by_id,
                                              document: qea_doc).render
          }.not_to raise_error, "render failed for #{diagram.name.inspect}"
        end
      end

      it "matches reference text content overlap above 0.4 on average" do
        images = images_dir(ex[:export])
        skip "no reference images for #{ex[:name]}" unless Dir.exist?(images)
        overlaps = []
        qea_doc.diagrams.each do |diagram|
          eaid = Ea::Sources::Qea::IdNormalizer.to_eaid(diagram.id)
          ref_path = File.join(images, "#{eaid}.svg")
          next unless File.exist?(ref_path)

          ours = Ea::Svg::EaEmitter::Document.new(diagram,
                                                    model_index: qea_doc.index_by_id,
                                                    document: qea_doc).render
          reference = File.read(ref_path)
          report = Ea::Svg::Parity::Checker.new(ours: ours, reference: reference).report
          overlaps << report.text_overlap
        end
        skip "no matching reference SVGs" if overlaps.empty?
        avg = overlaps.sum / overlaps.size.to_f
        # Loose threshold — catches gross regressions without failing
        # on the known per-example parity gaps (HTML note body,
        # legend block, ghost discriminator — see TODO.diagrams/).
        expect(avg).to be > 0.4,
                       "avg text overlap #{avg.round(3)} < 0.4 across #{overlaps.size} diagrams"
      end
    end
  end
end
