# frozen_string_literal: true

require "spec_helper"
require "ea/transformers/qea_to_xmi"

RSpec.describe Ea::Transformers::QeaToXmi::XmlSanitizer do
  def sanitize(xml)
    described_class.call(xml)
  end

  describe "empty / no-op cases" do
    it "handles an empty document" do
      result = sanitize("<root/>")
      expect(Nokogiri::XML(result).root.name).to eq("root")
    end

    it "preserves a single element with no children" do
      # Root is never stripped — only its descendants
      result = sanitize("<root><child/></root>")
      parsed = Nokogiri::XML(result)
      expect(parsed.root.children.select(&:element?).size).to eq(0)
    end
  end

  describe "truly-empty elements (no attrs, no children, no text)" do
    it "strips a flat empty child" do
      xml = "<root><empty/></root>"
      parsed = Nokogiri::XML(sanitize(xml))
      expect(parsed.xpath("//empty")).to be_empty
    end

    it "strips a nested chain in a single pass" do
      # <a><b><c/></b></a> → remove c → b becomes empty → remove b →
      # a becomes empty → remove a. All from one depth-first walk.
      xml = "<root><a><b><c/></b></a></root>"
      parsed = Nokogiri::XML(sanitize(xml))
      expect(parsed.xpath("//a")).to be_empty
      expect(parsed.xpath("//b")).to be_empty
      expect(parsed.xpath("//c")).to be_empty
    end

    it "strips multiple sibling empty elements" do
      xml = "<root><a/><b/><c/></root>"
      parsed = Nokogiri::XML(sanitize(xml))
      expect(parsed.root.children.select(&:element?)).to be_empty
    end
  end

  describe "preservation rules" do
    it "preserves an element with attributes" do
      xml = '<root><generalization general="EAID_x"/></root>'
      parsed = Nokogiri::XML(sanitize(xml))
      expect(parsed.xpath("//generalization").size).to eq(1)
    end

    it "preserves an element with text content" do
      xml = "<root><comment>hello</comment></root>"
      parsed = Nokogiri::XML(sanitize(xml))
      expect(parsed.xpath("//comment").size).to eq(1)
    end

    it "preserves an element with a non-empty child" do
      xml = '<root><parent><child attr="v"/></parent></root>'
      parsed = Nokogiri::XML(sanitize(xml))
      expect(parsed.xpath("//parent").size).to eq(1)
      expect(parsed.xpath("//child").size).to eq(1)
    end

    it "preserves the root element even when empty" do
      xml = "<root/>"
      parsed = Nokogiri::XML(sanitize(xml))
      expect(parsed.root).not_to be_nil
      expect(parsed.root.name).to eq("root")
    end
  end

  describe "mixed scenarios" do
    it "strips empty leaves but keeps their parent if it has attributes" do
      xml = '<assoc id="EAID_a"><memberEnd/><memberEnd idref="EAID_b"/></assoc>'
      parsed = Nokogiri::XML(sanitize(xml))
      # First memberEnd had no attrs → stripped
      # Second memberEnd had idref → kept
      kept = parsed.xpath("//memberEnd")
      expect(kept.size).to eq(1)
      expect(kept.first["idref"]).to eq("EAID_b")
    end

    it "does not double-process when output is re-sanitised" do
      xml = "<root><a/></root>"
      once = sanitize(xml)
      twice = sanitize(once)
      expect(twice).to eq(once)
    end
  end
end
