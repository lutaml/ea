# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Rtf do
  describe ".to_text" do
    it "returns nil unchanged" do
      expect(described_class.to_text(nil)).to be_nil
    end

    it "returns empty strings unchanged" do
      expect(described_class.to_text("")).to eq("")
    end

    it "passes plain text through untouched" do
      text = "Simple plain note\nwith a newline"
      expect(described_class.to_text(text)).to eq(text)
    end

    it "passes text that merely contains braces through untouched" do
      text = "pseudo {not rtf} content"
      expect(described_class.to_text(text)).to eq(text)
    end

    it "strips formatting control words" do
      rtf = "{\\rtf1\\ansi\\deff0 plain {\\b bold} {\\i ital} text}"
      expect(described_class.to_text(rtf)).to eq("plain bold ital text")
    end

    it "converts \\par and \\line to newlines and \\tab to tabs" do
      rtf = "{\\rtf1 first\\par second\\line third\\tab fourth}"
      expect(described_class.to_text(rtf)).to eq("first\nsecond\nthird\tfourth")
    end

    it "drops fonttbl/colortbl/stylesheet metadata groups" do
      rtf = "{\\rtf1{\\fonttbl{\\f0\\froman Times;}{\\f1 Arial;}}" \
            "{\\colortbl;\\red0\\green0\\blue0;}\\f0\\fs20 body text}"
      expect(described_class.to_text(rtf)).to eq("body text")
    end

    it "drops \\* destination groups like generator" do
      rtf = "{\\rtf1{\\*\\generator Riched20 10.0.19041}visible}"
      expect(described_class.to_text(rtf)).to eq("visible")
    end

    it "decodes \\'hh bytes as CP1252" do
      rtf = "{\\rtf1 caf\\'e9}"
      expect(described_class.to_text(rtf)).to eq("café")
    end

    it "decodes \\uNNNN unicode escapes and skips the fallback char" do
      rtf = "{\\rtf1 \\u9731? snow}"
      expect(described_class.to_text(rtf)).to eq("☃ snow")
    end

    it "preserves escaped braces and backslashes" do
      rtf = "{\\rtf1 a \\\\ b \\{ c \\} d}"
      expect(described_class.to_text(rtf)).to eq("a \\ b { c } d")
    end

    it "keeps text after nested groups closes" do
      rtf = "{\\rtf1\\ansi before {\\b{\\i deep}} after}"
      expect(described_class.to_text(rtf)).to eq("before deep after")
    end

    it "handles notes that begin with whitespace before the RTF header" do
      rtf = "  {\\rtf1 indented note}"
      expect(described_class.to_text(rtf)).to eq("indented note")
    end
  end
end
