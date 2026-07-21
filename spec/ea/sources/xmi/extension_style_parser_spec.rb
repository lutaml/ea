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

    it "scales fontsz percentage to pixel size" do
      parsed = described_class.parse(style)
      expect(parsed.font_size).to eq(13) # 100% of 13
    end

    it "extracts DUID" do
      parsed = described_class.parse(style)
      expect(parsed.duid).to eq("7CBAFC69")
    end

    it "parses fontsz=200 as 26px" do
      parsed = described_class.parse("fontsz=200;")
      expect(parsed.font_size).to eq(26)
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
end
