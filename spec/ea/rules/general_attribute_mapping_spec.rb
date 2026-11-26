# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Rules::GeneralAttributeMapping do
  describe ".build" do
    it "constructs a GeneralAttribute with the shared field list" do
      attr = described_class.build(
        id: 7,
        name: "lat",
        type: "Real",
        xmi_id: "EAID_7",
        cardinality: "0..1",
        definition: "  latitude  ",
        association: nil,
        type_ns: "gml",
        is_derived: true
      )

      aggregate_failures do
        expect(attr).to be_a(Lutaml::Uml::GeneralAttribute)
        expect(attr.id).to eq("7")
        expect(attr.name).to eq("lat")
        expect(attr.type).to eq("Real")
        expect(attr.xmi_id).to eq("EAID_7")
        expect(attr.cardinality).to eq("0..1")
        expect(attr.definition).to eq("  latitude  ")
        expect(attr.type_ns).to eq("gml")
        expect(attr.is_derived).to be(true)
        expect(attr.has_association).to be(false)
        expect(attr.association).to be_nil
      end
    end

    it "normalizes is_derived boolean-or-nil" do
      plain = described_class.build(id: 1, name: "a", type: "T",
                                    is_derived: nil, definition: nil)
      falsey = described_class.build(id: 1, name: "a", type: "T",
                                     is_derived: false, definition: nil)
      aggregate_failures do
        expect(plain.is_derived).to be(false)
        expect(falsey.is_derived).to be(false)
      end
    end

    it "mirrors has_association from the association reference" do
      with_assoc = described_class.build(id: 1, name: "a", type: "T",
                                         association: "EAID_assoc",
                                         definition: nil)
      without = described_class.build(id: 1, name: "a", type: "T",
                                      association: nil, definition: nil)
      aggregate_failures do
        expect(with_assoc.has_association).to be(true)
        expect(without.has_association).to be(false)
      end
    end

    it "keeps the definition verbatim (walkers own stripping)" do
      attr = described_class.build(id: 1, name: "a", type: "T",
                                   definition: nil)
      expect(attr.definition).to be_nil
    end
  end
end
