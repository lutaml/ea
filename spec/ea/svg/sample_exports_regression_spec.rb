# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/parity"
require "xmi"

# Optional wider measurement against a local plateau export. The
# committed parity gate (spec/fixtures/parity) is the CI check; this
# spec only runs when EA_PLATEAU_XMI and EA_PLATEAU_REF_DIR are set.
module PlateauHelpers
  def plateau_doc
    root = Xmi::Sparx::Root.parse_xml(File.read(plateau_xmi))
    Ea::Sources::Xmi::Adapter.new(root, plateau_xmi).to_document
  end
end

RSpec.describe "EA sample exports regression", :sample_exports_regression do
  include PlateauHelpers

  let(:plateau_xmi) { ENV.fetch("EA_PLATEAU_XMI", nil) }
  let(:plateau_ref_dir) { ENV.fetch("EA_PLATEAU_REF_DIR", nil) }

  describe "full plateau (192 reference SVGs)", :full_plateau do
    before do
      skip "set EA_PLATEAU_XMI to run" unless plateau_xmi && File.exist?(plateau_xmi)
      skip "set EA_PLATEAU_REF_DIR to run" unless plateau_ref_dir && Dir.exist?(plateau_ref_dir)
    end

    it "renders every plateau diagram without raising" do
      doc = plateau_doc
      doc.diagrams.each do |diagram|
        expect do
          Ea::Svg::EaEmitter::Document.new(diagram, model_index: doc.index_by_id, frame: true).render
        end.not_to raise_error
      end
    end

    it "matches reference shape counts within tolerance for most diagrams" do
      suite = Ea::Svg::Parity::Suite.new(plateau_doc, plateau_ref_dir).measure
      within = suite.per_diagram.count { |dr| dr.report.shape_delta_total <= 5 }
      outliers = suite.outliers(shape_tolerance: 5).first(5).map(&:id)

      expect(within.to_f / suite.total).to be > 0.6,
                                           "only #{within}/#{suite.total} within tolerance; " \
                                           "first 5 outliers:\n#{outliers.join("\n")}"
    end
  end
end
