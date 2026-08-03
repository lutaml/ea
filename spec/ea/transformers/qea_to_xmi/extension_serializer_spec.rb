# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Transformers::QeaToXmi::ExtensionSerializer do
  let(:database) { Ea::Qea.load("examples/qea/basic.qea") }
  let(:context) do
    Ea::Transformers::QeaToXmi::Context.new(database: database)
  end
  let(:serializer) { described_class.new(database, context) }

  after { database.close_connection }

  describe "#call" do
    subject(:output) { serializer.call }

    it "returns a non-empty string" do
      expect(output).to be_a(String)
      expect(output).not_to be_empty
    end

    it "includes <elements> section" do
      expect(output).to include("<elements>")
      expect(output).to include("</elements>")
    end

    it "includes <connectors> section" do
      expect(output).to include("<connectors>")
    end

    it "includes <diagrams> section" do
      expect(output).to include("<diagrams>")
    end

    it "emits per-element <style> blocks" do
      expect(output.scan(%r{<style[\s/>]}).size).to be > 50
    end

    it "emits per-element <tags> blocks" do
      expect(output.scan(%r{<tags[\s/>]}).size).to be > 50
    end

    it "emits <documentation> elements for attributes" do
      expect(output.scan(%r{<documentation[\s/>]}).size).to be > 10
    end
  end

  describe "UML_TYPE_FOR registry" do
    it "maps Class to uml:Class" do
      expect(described_class::UML_TYPE_FOR["Class"]).to eq("uml:Class")
    end

    it "maps Interface to uml:Interface" do
      expect(described_class::UML_TYPE_FOR["Interface"]).to eq("uml:Interface")
    end

    it "maps Enumeration to uml:Enumeration" do
      expect(described_class::UML_TYPE_FOR["Enumeration"]).to eq("uml:Enumeration")
    end

    it "maps PrimitiveType to uml:PrimitiveType" do
      expect(described_class::UML_TYPE_FOR["PrimitiveType"]).to eq("uml:PrimitiveType")
    end
  end

  describe "SKIP_OBJECT_TYPES" do
    it "includes Note" do
      expect(described_class::SKIP_OBJECT_TYPES).to include("Note")
    end

    it "includes Text" do
      expect(described_class::SKIP_OBJECT_TYPES).to include("Text")
    end

    it "includes ProxyConnector" do
      expect(described_class::SKIP_OBJECT_TYPES).to include("ProxyConnector")
    end
  end
end
