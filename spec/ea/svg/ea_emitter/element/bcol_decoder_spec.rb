# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/element/bcol_decoder"

RSpec.describe Ea::Svg::EaEmitter::Element::BColDecoder do
  describe ".to_hex" do
    it "returns nil for nil input" do
      expect(described_class.to_hex(nil)).to be_nil
    end

    it "returns nil for the -1 sentinel (no override)" do
      expect(described_class.to_hex(-1)).to be_nil
    end

    it "decodes pure black (BGR=0)" do
      expect(described_class.to_hex(0)).to eq("#000000")
    end

    it "decodes pure white (BGR=16777215)" do
      expect(described_class.to_hex(16_777_215)).to eq("#FFFFFF")
    end

    it "decodes BGR to RGB hex (red in low byte)" do
      # BGR int 255 = 0x0000FF → byte order B=0, G=0, R=255 → red
      expect(described_class.to_hex(255)).to eq("#FF0000")
    end

    it "decodes BGR int 65280 (0x00FF00) to green" do
      expect(described_class.to_hex(65_280)).to eq("#00FF00")
    end

    it "decodes BGR int 16711680 (0xFF0000) to blue" do
      expect(described_class.to_hex(16_711_680)).to eq("#0000FF")
    end

    it "decodes a compound color (BGR=0xCCFFCC → R=CC G=FF B=CC)" do
      # 0xCCFFCC = 13,434,828. High byte = B = 0xCC, mid = G = 0xFF,
      # low = R = 0xCC. Expected hex: "#CCFFCC".
      expect(described_class.to_hex(13_434_828)).to eq("#CCFFCC")
    end

    it "uppercase the hex digits" do
      expect(described_class.to_hex(255)).to match(/^#[0-9A-F]{6}$/)
    end
  end
end
