# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Sources::Xmi::ExtensionStyleParser do
  describe ".parse for element style" do
    let(:style) do
      "NSL=0;LCol=-1;bold=0;black=0;italic=0;ul=0;charset=0;HideIcon=0;BCol=16764159;font=Yu Gothic UI;pitch=50;BFol=0;fontsz=100;DUID=7CBAFC69;LWth=2;"
    end

    it "extracts background color (BCol)" do
      parsed = described_class.parse(style)
      expect(parsed.background_color).to eq(16_764_159)
    end

    it "extracts line width (LWth)" do
      parsed = described_class.parse(style)
      expect(parsed.line_width).to eq(2)
    end

    it "extracts font family" do
      parsed = described_class.parse(style)
      expect(parsed.font_family).to eq("Yu Gothic UI")
    end

    it "maps an explicit fontsz to points the way the QEA builder does" do
      parsed = described_class.parse(style)
      expect(parsed.font_size).to eq(9)
    end

    it "extracts DUID" do
      parsed = described_class.parse(style)
      expect(parsed.duid).to eq("7CBAFC69")
    end

    it "maps fontsz=90 and fontsz=200 like QEA" do
      expect(described_class.parse("fontsz=90;").font_size).to eq(9)
      expect(described_class.parse("fontsz=200;").font_size).to eq(19)
    end

    it "leaves absent, empty and zero fontsz as inherited" do
      ["", "bold=0;", "fontsz=;", "fontsz=0;"].each do |raw|
        expect(described_class.parse(raw).font_size).to be_nil
      end
    end
  end

  describe ".parse for connector style" do
    let(:style) do
      "Mode=3;EOID=332E1397;SOID=9766BB81;Color=-1;LWidth=2;Hidden=0;"
    end

    it "extracts SOID and EOID" do
      parsed = described_class.parse(style)
      expect(parsed.soid).to eq("9766BB81")
      expect(parsed.eoid).to eq("332E1397")
    end

    it "extracts LWidth (connector variant of LWth)" do
      parsed = described_class.parse(style)
      expect(parsed.line_width).to eq(2)
    end

    it "extracts Hidden flag" do
      parsed = described_class.parse("Mode=3;Hidden=1;")
      expect(parsed.hidden).to be(true)
    end
  end

  describe ".parse with a key preceded by a space" do
    it "reads the key like the QEA style parser" do
      parsed = described_class.parse(" DUID=AB12CD34;SOID=11111111;")
      expect([parsed.duid, parsed.soid]).to eq(%w[AB12CD34 11111111])
    end
  end
end
