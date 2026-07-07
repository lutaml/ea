# frozen_string_literal: true

require "spec_helper"
require "ea/cli/app"

# End-to-end parity specs for the XMI parser. These exercise
# `Ea::Transformations.parse` with the same fixture that drives the
# QEA parser specs and assert the XMI output now matches on
# document-level collection counts.
RSpec.describe "XMI parser parity with QEA" do
  let(:qea_path) { fixtures_path("basic.qea") }
  let(:xmi_path) { fixtures_path("basic.xmi") }

  let(:qea_document) { Ea::Transformations.parse(qea_path) }
  let(:xmi_document) { Ea::Transformations.parse(xmi_path) }

  def self.walk_for_total(node, acc)
    acc[:packages] += 1
    acc[:classes] += (node.respond_to?(:classes) ? node.classes.size : 0)
    acc[:instances] += (node.respond_to?(:instances) ? node.instances.size : 0)
    acc[:enums] += (node.respond_to?(:enums) ? node.enums.size : 0)
    (node.respond_to?(:packages) ? node.packages : []).each do |child|
      walk_for_total(child, acc)
    end
  end

  def total_for(document)
    total = { packages: 0, classes: 0, instances: 0, enums: 0 }
    document.packages.each { |p| self.class.walk_for_total(p, total) }
    total
  end

  describe "document-level collection counts" do
    it "XMI document has 22 diagrams (was 0 before fix)" do
      expect(xmi_document.diagrams.size).to eq(22)
    end

    it "XMI document has package-level associations (was 0 before fix)" do
      expect(xmi_document.associations.size).to be > 30
    end

    it "XMI document has a non-empty packages tree" do
      expect(xmi_document.packages).not_to be_empty
    end
  end

  describe "nested package + class + instance tree walk" do
    it "XMI preserves full package hierarchy (42 packages in basic.xmi)" do
      expect(total_for(xmi_document)[:packages]).to eq(42)
    end

    it "XMI preserves InstanceSpecifications (12 in basic.xmi)" do
      expect(total_for(xmi_document)[:instances]).to eq(12)
    end

    it "XMI preserves classes including Signal/Component variants (>= 30)" do
      expect(total_for(xmi_document)[:classes]).to be >= 30
    end
  end

  describe "package-level Association extraction" do
    it "every Association has an xmi:id" do
      xmi_document.associations.each do |assoc|
        expect(assoc.xmi_id).to match(/\AEAID_/)
      end
    end

    it "every Association has resolved owner_end and member_end" do
      xmi_document.associations.each do |assoc|
        expect(assoc.owner_end).not_to be_nil,
                                       "association #{assoc.xmi_id.inspect} has no owner_end"
      end
    end
  end

  describe "round-trip on the same QEA-exported XMI" do
    it "produces a Document with the same package count as QEA" do
      expect(total_for(xmi_document)[:packages]).to eq(total_for(qea_document)[:packages])
    end
  end
end
