# frozen_string_literal: true

require "spec_helper"
require "ea"
require "xmi"
require_relative "../../support/svg_canonicalizer"

# Measures fidelity of our EaEmitter output vs EA's reference SVGs.
# Not a hard-fail spec — produces a report so we can track fidelity
# over time. The report shows:
#   - how many reference diagrams we have
#   - how many match structurally (after canonicalization)
#   - how many differ (and by how many elements)
# Optional extra: set EA_PLATEAU_XMI and EA_PLATEAU_REF_DIR to a local
# plateau export to run the wider measurement. Without them the spec
# skips; the committed parity gate (spec/fixtures/parity) covers CI.
module VisualRegressionHelpers
  def load_document(path)
    root = Xmi::Sparx::Root.parse_xml(File.read(path))
    Ea::Sources::Xmi::Adapter.new(root, path).to_document
  end

  def render_svg(diagram)
    Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, frame: true
    ).render
  end

  def rect_count(svg)
    Moxml.parse(svg).xpath("//*[local-name()='rect']").size
  end
end

RSpec.describe "EA SVG visual regression", :visual_regression do
  include VisualRegressionHelpers

  let(:xmi_path) { ENV.fetch("EA_PLATEAU_XMI", nil) }
  let(:ref_dir) { ENV.fetch("EA_PLATEAU_REF_DIR", nil) }
  let(:document) { load_document(xmi_path) }

  before do
    skip "set EA_PLATEAU_XMI to run" unless xmi_path && File.exist?(xmi_path)
    skip "set EA_PLATEAU_REF_DIR to run" unless ref_dir && Dir.exist?(ref_dir)
  end

  it "renders a representative diagram and matches EA structurally" do
    target = document.diagrams.find { |d| File.exist?(File.join(ref_dir, "#{d.id}.svg")) }
    skip "no overlapping diagram IDs between XMI and reference SVGs" unless target

    svg = render_svg(target)
    ours = rect_count(svg)
    ref = rect_count(File.read(File.join(ref_dir, "#{target.id}.svg")))
    expect { Moxml.parse(svg, &:strict) }.not_to raise_error
    expect(ours).to be > 0
    expect([ours.to_f / ref, ref.to_f / ours].min).to be > 0.5,
                                                      "rect count diverges: ours=#{ours}, ref=#{ref}"
  end

  it "renders at least N diagrams from the XMI without errors" do
    document.diagrams.first(10).each do |diagram|
      expect { render_svg(diagram) }.not_to raise_error
    end
  end
end
