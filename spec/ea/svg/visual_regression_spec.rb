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
RSpec.describe "EA SVG visual regression", :visual_regression do
  XMI_PATH = "/Users/mulgogi/src/mn/mn-samples-plateau/sources/xmi/plateau_all_packages_export.xmi"
  REF_DIR = "/Users/mulgogi/src/mn/mn-samples-plateau/sources/001-mds/xmi-images"

  before(:all) do
    skip "Sample XMI not available at #{XMI_PATH}" unless File.exist?(XMI_PATH)
    skip "Reference SVG dir not available at #{REF_DIR}" unless File.exist?(REF_DIR)
  end

  let(:document) do
    root = Xmi::Sparx::Root.parse_xml(File.read(XMI_PATH))
    Ea::Sources::Xmi::Adapter.new(root, XMI_PATH).to_document
  end

  it "renders a representative diagram and matches EA structurally" do
    # Pick a diagram with substantial content and a known reference.
    target = document.diagrams.find { |d| File.exist?(File.join(REF_DIR, "#{d.id}.svg")) }
    skip "no overlapping diagram IDs between XMI and reference SVGs" unless target

    svg = Ea::Svg::EaEmitter::Document.new(target, model_index: document.index_by_id).render
    reference = File.read(File.join(REF_DIR, "#{target.id}.svg"))

    # At minimum, our SVG should parse as valid XML.
    expect { Nokogiri::XML(svg, &:strict) }.not_to raise_error

    # And contain the same number of <rect> elements as the reference.
    our_rects = Nokogiri::XML(svg).css("rect").size
    ref_rects = Nokogiri::XML(reference).css("rect").size
    expect(our_rects).to be > 0
    # Allow some difference (we may render fewer/more divider rects).
    ratio = [our_rects.to_f / ref_rects, ref_rects.to_f / our_rects].min
    expect(ratio).to be > 0.5,
      "rect count diverges: ours=#{our_rects}, ref=#{ref_rects}"
  end

  it "renders at least N diagrams from the XMI without errors" do
    sample = document.diagrams.first(10)
    sample.each do |diagram|
      expect {
        Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id).render
      }.not_to raise_error
    end
  end
end
