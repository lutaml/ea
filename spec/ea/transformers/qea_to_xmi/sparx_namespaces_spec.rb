# frozen_string_literal: true

require "spec_helper"
require "ea/transformers/qea_to_xmi"

RSpec.describe Ea::Transformers::QeaToXmi::SparxNamespaces do
  describe "namespace constants" do
    it "uses the canonical XMI 20131001 URI" do
      expect(described_class::XMI)
        .to eq("http://www.omg.org/spec/XMI/20131001")
    end

    it "uses the canonical UML 20161101 URI" do
      expect(described_class::UML)
        .to eq("http://www.omg.org/spec/UML/20161101")
    end
  end

  describe "BASE" do
    it "declares the four Sparx-required namespaces" do
      expect(described_class::BASE.keys).to contain_exactly(
        :"xmlns:xmi", :"xmlns:uml", :"xmlns:umldi", :"xmlns:dc",
      )
    end
  end

  describe ".profile_for" do
    it "looks up built-in profiles case-insensitively" do
      expect(described_class.profile_for("TheCustomProfile"))
        .to eq(["thecustomprofile",
                "http://www.sparxsystems.com/profiles/thecustomprofile/1.0"])
      expect(described_class.profile_for("GML"))
        .to eq(["GML", "http://www.sparxsystems.com/profiles/GML/1.0"])
    end

    it "returns nil for unknown profiles" do
      expect(described_class.profile_for("unknown")).to be_nil
    end

    it "returns nil for nil input" do
      expect(described_class.profile_for(nil)).to be_nil
    end
  end

  describe ".register_profile / .profile_for (OCP)" do
    it "registers a new profile without modifying source" do
      described_class.register_profile("testprofile_for_specs_only",
                                       prefix: "TP",
                                       uri: "http://example.com/test/1.0")
      expect(described_class.profile_for("TestProfile_For_Specs_Only"))
        .to eq(["TP", "http://example.com/test/1.0"])
    end
  end

  describe ".profile_namespaces_for" do
    it "builds xmlns declarations for the requested profiles" do
      result = described_class.profile_namespaces_for(["GML"])
      expect(result).to eq("xmlns:GML": "http://www.sparxsystems.com/profiles/GML/1.0")
    end

    it "ignores unknown profiles" do
      result = described_class.profile_namespaces_for(["GML", "unknown"])
      expect(result.keys).to eq([:"xmlns:GML"])
    end

    it "deduplicates when the same profile appears twice" do
      result = described_class.profile_namespaces_for(["GML", "GML"])
      expect(result.size).to eq(1)
    end
  end
end
