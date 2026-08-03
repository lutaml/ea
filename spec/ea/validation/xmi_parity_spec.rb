# frozen_string: true

require "spec_helper"

# Validates QEA→XMI export fidelity against EA's reference exports
# in examples/exports/*/model.xml. Each delta is documented as a
# known gap; the spec surfaces regressions (delta should not grow).
RSpec.describe "QEA → XMI parity (vs EA reference exports)" do
  PAIRS = [
    ["examples/qea/basic.qea", "examples/exports/basic/model.xml"],
    ["examples/qea/test.qea", "examples/exports/test/model.xml"],
    ["examples/qea/simple.qea", "examples/exports/simple/model.xml"],
    ["examples/qea/simple_example.qea",
     "examples/exports/simple_example/model.xml"],
    ["examples/qea/UmlModel_template.qea",
     "examples/exports/UmlModel_template/model.xml"],
    ["examples/qea/ArcGISWorkspace_template.qea",
     "examples/exports/ArcGISWorkspace_template/model.xml"]
  ].freeze

  PAIRS.each do |qea, ref|
    next unless File.exist?(qea) && File.exist?(ref)

    describe "#{File.basename(qea, '.qea')} ↔ #{File.basename(File.dirname(ref))}" do
      let(:result) { Ea::Validation::XmiParity.compare(qea, ref) }

      it "produces non-empty XMI" do
        expect(result[:ours].total).to be > 0
      end

      # These are KNOWN gaps. Each asserts a minimum threshold so
      # regressions surface. As QeaToXmi is improved, raise the
      # thresholds or replace with exact-match assertions.
      it "matches EA on memberEnd count" do
        delta = result[:delta][:memberEnd] || 0
        # ownedEnd is structurally tied to memberEnd; both should
        # match when associations serialize correctly.
        expect(delta).to eq(0),
          "memberEnd delta: ours produced #{result[:ours].by_type['memberEnd']}, " \
          "EA ref has #{result[:reference_counts].by_type['memberEnd']}"
      end

      it "matches EA on generalization count" do
        delta = result[:delta][:generalization] || 0
        expect(delta).to eq(0),
          "generalization delta: ours=#{result[:ours].by_type['generalization']}, " \
          "ref=#{result[:reference_counts].by_type['generalization']}"
      end

      it "produces at least 5% of EA's packagedElement count" do
        # QeaToXmi is currently much less complete than EA's export.
        # This threshold catches catastrophic regressions. Raise
        # the percentage as QeaToXmi gains fidelity (e.g. starts
        # emitting connectors, diagrams, styles, tags, documentation).
        ours = result[:ours].by_type["packagedElement"] || 0
        ref_count = result[:reference_counts].by_type["packagedElement"] || 0
        threshold = (ref_count * 0.05).ceil
        expect(ours).to be >= threshold,
          "packagedElement: ours=#{ours}, ref=#{ref_count}, " \
          "threshold=#{threshold}"
      end
    end
  end

  describe "Ea::Validation::XmiParity.count" do
    it "counts element types correctly" do
      xml = <<~XML
        <xmi:XMI>
          <packagedElement/>
          <packagedElement/>
          <ownedAttribute/>
          <connector/>
        </xmi:XMI>
      XML
      counts = Ea::Validation::XmiParity.count(xml)
      expect(counts.by_type["packagedElement"]).to eq(2)
      expect(counts.by_type["ownedAttribute"]).to eq(1)
      expect(counts.by_type["connector"]).to eq(1)
      expect(counts.total).to eq(4)
    end
  end
end
