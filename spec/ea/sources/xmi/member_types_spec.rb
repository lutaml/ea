# frozen_string_literal: true

require "spec_helper"
require "ea"
require "xmi"

RSpec.describe "Sparx XMI attribute and operation types" do
  include XmiUnnamedAssociationHelpers
  let(:path) { fixtures_path("basic.xmi") }
  let(:document) { Ea::Sources::Xmi::Adapter.from_path(path) }
  let(:classifiers) { document.classifiers }

  let(:properties) { classifiers.flat_map(&:properties) }

  describe "attributes typed by a primitive href" do
    it "takes the type name EA stores in the extension" do
      attribute_a = properties.find { |p| p.id == "EAID_DBEBCF83_9F6F_4a48_A174_3C6B9410FC4E" }

      expect(attribute_a.type_name).to eq("int")
    end
  end

  describe "attributes typed by an EA placeholder idref" do
    it "takes the type name EA stores in the extension" do
      attribute_one = properties.find { |p| p.id == "EAID_4D665E05_CA01_4c63_8311_0EC8F355E932" }

      expect(attribute_one.type_name).to eq("typeOne")
    end
  end

  describe "attributes typed by a classifier idref" do
    it "keeps the in-model qualified name" do
      end_property = named_association_document.classifiers.flat_map(&:properties)
                                               .find { |p| p.id == "EAID_dstCF64D9_3CAA_41e2_862C_8C4A9BA09AC2" }

      expect(end_property.type_name).to eq("Classes::Class B")
    end
  end

  describe "operations" do
    let(:operation) do
      classifiers.flat_map(&:operations)
                 .find { |o| o.id == "EAID_DE87DA1F_3EE1_4598_9615_F2068D192111" }
    end

    it "defaults visibility to public" do
      expect(operation.visibility).to eq("public")
    end

    it "takes the return type from the extension" do
      expect(operation.return_type_name).to eq("void")
    end

    it "keeps only the non-return parameters, typed and directed in" do
      expect(operation.parameters.map { |p| [p.name, p.type_name, p.direction] })
        .to eq([["Parameter A", "int", "in"]])
    end
  end
end
