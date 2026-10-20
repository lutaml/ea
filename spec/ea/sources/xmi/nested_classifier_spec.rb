# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe Ea::Sources::Xmi::Adapter, "nested classifiers" do # rubocop:disable Metrics/BlockLength
  include XmiBasicRouteLabelHelpers
  include XmiNestedClassifierHelpers

  before(:context) do
    @basic_route_label_document = QeaBridgeCorpusHelpers.document_for(
      described_class, "spec/fixtures/basic.xmi"
    )
  end

  let(:document) { @basic_route_label_document }
  let(:nested) do
    document.classifiers.find { |c| c.id == "EAID_E8C11766_B447_45ad_81C8_9D0DE88755A7" }
  end

  it "builds a nestedClassifier class with its attributes" do
    aggregate_failures do
      expect(nested.name).to eq("Class A.4.3")
      expect(nested.properties.map(&:name)).to eq(["Attribute 1", "Attribute 2"])
    end
  end

  it "assigns the enclosing package and owner class" do
    aggregate_failures do
      expect(nested.package_id).to eq("EAPK_D089A7D9_B842_42fc_8E94_3378E01C2483")
      expect(nested.nested_parent_name).to eq("Class A.4")
      expect(nested.qualified_name).to eq("Class A.4::Class A.4.3")
    end
  end

  it "keeps top-level class qualification unchanged" do
    top = document.classifiers.find { |c| c.name == "Class A" }
    aggregate_failures do
      expect(top.nested_parent_name).to be_nil
      expect(top.qualified_name).to eq("Basic Class Diagram with Multiplicities::Class A")
    end
  end

  it "includes nested classifiers once in their package" do
    package = document.packages.find { |item| item.id == nested.package_id }
    ids = document.classifiers.map(&:id)

    aggregate_failures do
      expect(package.classifier_ids).to include(nested.id)
      expect(package.classifier_ids.uniq).to eq(package.classifier_ids)
      expect(ids.uniq).to eq(ids)
    end
  end

  it "builds the nested generalization with both endpoints" do
    relationship = document.relationships.find do |item|
      item.id == "EAID_82F305AE_40F4_4938_AAE7_874391023FFF"
    end

    aggregate_failures do
      expect(relationship).to be_a(Ea::Model::Generalization)
      expect(relationship&.specific_id).to eq("EAID_8A2510A3_8F80_42b7_9E53_A85461F2F3A6")
      expect(relationship&.general_id).to eq("EAID_6284176A_7C2D_4e36_9E87_947A194457BE")
    end
  end

  %w[372F7F7B 4FC1D352].each do |diagram_id|
    it "renders every class of nested diagram #{diagram_id}" do
      names = basic_route_label_text(diagram_id).grep(/\AClass A/)

      expect(names).to match_array(
        ["", ".1", ".1.1", ".1.2", ".1.3", ".2", ".2.1", ".2.2", ".2.3", ".3",
         ".3.1", ".3.2", ".3.3", ".4", ".4.1", ".4.2", ".4.3"].map { |s| "Class A#{s}" }
      )
    end
  end

  context "with relationships inside a nested classifier" do
    let(:document) { nested_classifier_document }

    it "builds the nested association and generalization once" do
      aggregate_failures do
        expect(document.relationships.map(&:id)).to match_array(%w[association generalization])
        expect(document.index_by_id["association"].source_id).to eq("child")
        expect(document.index_by_id["association"].target_id).to eq("root")
        expect(document.index_by_id["generalization"].specific_id).to eq("child")
        expect(document.index_by_id["generalization"].general_id).to eq("root")
      end
    end

    it "preserves model and subpackage ownership" do
      aggregate_failures do
        expect(document.index_by_id["root"].package_id).to be_nil
        expect(document.index_by_id["package"].classifier_ids).to eq(%w[owner child])
        expect(document.index_by_id["subpackage"].classifier_ids).to eq(["other"])
        expect(document.index_by_id["child"].package_id).to eq("package")
        expect(document.index_by_id["child"].nested_parent_name).to eq("Owner")
        expect(document.index_by_id["other"].nested_parent_name).to be_nil
      end
    end
  end
end
