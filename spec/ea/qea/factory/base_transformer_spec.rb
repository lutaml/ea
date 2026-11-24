# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Qea::Factory::BaseTransformer do
  let(:database) { Ea::Qea::Database.new("test.qea") }
  let(:transformer) { described_class.new(database) }

  describe "#initialize" do
    it "stores database reference" do
      expect(transformer.database).to eq(database)
    end
  end

  describe "#transform" do
    it "raises NotImplementedError" do
      expect { transformer.transform(nil) }.to raise_error(
        NotImplementedError,
        /must implement #transform/,
      )
    end
  end

  describe "#transform_collection" do
    let(:concrete_transformer) do
      Class.new(described_class) do
        def transform(item)
          return nil if item.nil?

          { transformed: item }
        end
      end.new(database)
    end

    it "transforms empty collection to empty array" do
      result = concrete_transformer.transform_collection([])
      expect(result).to eq([])
    end

    it "transforms nil collection to empty array" do
      result = concrete_transformer.transform_collection(nil)
      expect(result).to eq([])
    end

    it "transforms each item in collection" do
      items = [1, 2, 3]
      result = concrete_transformer.transform_collection(items)
      expect(result).to eq([
                             { transformed: 1 },
                             { transformed: 2 },
                             { transformed: 3 },
                           ])
    end

    it "filters out nil results" do
      items = [1, nil, 3]
      result = concrete_transformer.transform_collection(items)
      expect(result).to eq([
                             { transformed: 1 },
                             { transformed: 3 },
                           ])
    end
  end

  describe "#map_visibility" do
    it "maps 'Public' to 'public'" do
      result = transformer.map_visibility("Public")
      expect(result).to eq("public")
    end

    it "maps 'Private' to 'private'" do
      result = transformer.map_visibility("Private")
      expect(result).to eq("private")
    end

    it "maps 'Protected' to 'protected'" do
      result = transformer.map_visibility("Protected")
      expect(result).to eq("protected")
    end

    it "maps 'Package' to 'package'" do
      result = transformer.map_visibility("Package")
      expect(result).to eq("package")
    end

    it "defaults nil to 'public'" do
      result = transformer.map_visibility(nil)
      expect(result).to eq("public")
    end

    it "defaults empty string to 'public'" do
      result = transformer.map_visibility("")
      expect(result).to eq("public")
    end

    it "handles case insensitively" do
      result = transformer.map_visibility("PRIVATE")
      expect(result).to eq("private")
    end
  end

  describe "#parse_cardinality" do
    it "parses '0..1'" do
      result = transformer.parse_cardinality("0..1")
      expect(result).to eq(min: "0", max: "1")
    end

    it "parses '1..*'" do
      result = transformer.parse_cardinality("1..*")
      expect(result).to eq(min: "1", max: "*")
    end

    it "parses single value as both min and max" do
      result = transformer.parse_cardinality("1")
      expect(result).to eq(min: "1", max: "1")
    end

    it "parses bare '*' as unbounded 0..*" do
      result = transformer.parse_cardinality("*")
      expect(result).to eq(min: "0", max: "*")
    end

    it "returns nil values for nil input" do
      result = transformer.parse_cardinality(nil)
      expect(result).to eq(min: nil, max: nil)
    end

    it "returns nil values for empty string" do
      result = transformer.parse_cardinality("")
      expect(result).to eq(min: nil, max: nil)
    end
  end

  describe "#to_boolean" do
    it "returns false for nil" do
      result = transformer.to_boolean(nil)
      expect(result).to be false
    end

    it "returns true for '1'" do
      result = transformer.to_boolean("1")
      expect(result).to be true
    end

    it "returns false for '0'" do
      result = transformer.to_boolean("0")
      expect(result).to be false
    end

    it "returns true for 'true'" do
      result = transformer.to_boolean("true")
      expect(result).to be true
    end

    it "returns false for 'false'" do
      result = transformer.to_boolean("false")
      expect(result).to be false
    end

    it "returns true when passed true" do
      result = transformer.to_boolean(true)
      expect(result).to be true
    end

    it "returns false when passed false" do
      result = transformer.to_boolean(false)
      expect(result).to be false
    end

    it "handles case insensitively" do
      result = transformer.to_boolean("TRUE")
      expect(result).to be true
    end
  end

  describe "#normalize_guid_to_xmi_src_dst_format" do
    it "returns nil for nil GUID instead of crashing" do
      expect(transformer.normalize_guid_to_xmi_src_dst_format(nil)).to be_nil
    end

    it "returns nil for empty GUID" do
      expect(transformer.normalize_guid_to_xmi_src_dst_format("")).to be_nil
    end

    it "appends src/dst segment" do
      guid = "{AAAA1111-0000-0000-0000-000000000001}"
      expect(transformer.normalize_guid_to_xmi_src_dst_format(guid, "EAID", true))
        .to eq("EAID_srcAA1111_0000_0000_0000_000000000001")
      expect(transformer.normalize_guid_to_xmi_src_dst_format(guid, "EAID", false))
        .to eq("EAID_dstAA1111_0000_0000_0000_000000000001")
    end
  end

  describe "#normalize_note" do
    it "strips RTF markup and normalizes line endings" do
      rtf = "{\\rtf1\\ansi Note {\\b bold} text\\par  second line}"
      expect(transformer.normalize_note(rtf))
        .to eq("Note bold text\n second line")
    end

    it "passes plain text through with line-ending normalization" do
      expect(transformer.normalize_note("plain\r\nnote")).to eq("plain\nnote")
    end

    it "returns nil for nil" do
      expect(transformer.normalize_note(nil)).to be_nil
    end
  end
end
