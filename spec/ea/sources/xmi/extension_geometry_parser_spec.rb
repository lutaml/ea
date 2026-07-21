# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Sources::Xmi::ExtensionGeometryParser do
  describe ".parse for placement rows" do
    let(:geom) do
      "Left=0;Top=728;Right=243;Bottom=867;imgL=25;imgT=758;imgR=268;imgB=897;"
    end

    it "extracts logical bounds" do
      parsed = described_class.parse(geom)
      expect(parsed.left).to eq(0)
      expect(parsed.top).to eq(728)
      expect(parsed.right).to eq(243)
      expect(parsed.bottom).to eq(867)
    end

    it "extracts image (padded) bounds" do
      parsed = described_class.parse(geom)
      expect(parsed.img_left).to eq(25)
      expect(parsed.img_top).to eq(758)
      expect(parsed.img_right).to eq(268)
      expect(parsed.img_bottom).to eq(897)
    end
  end

  describe ".parse for connector rows" do
    let(:geom) do
      "SX=5;SY=55;EX=5;EY=50;EDGE=4;$LLB=CX=19:CY=16:OX=-50:OY=-34:HDN=0:BLD=0:ITA=0:UND=0:CLR=-1:ALN=1:DIR=0:ROT=0;LLT=;LMT=;LMB=;LRT=;LRB=;IRHS=;ILHS=;Path=;"
    end

    it "extracts bend deltas" do
      parsed = described_class.parse(geom)
      expect(parsed.sx).to eq(5)
      expect(parsed.sy).to eq(55)
      expect(parsed.ex).to eq(5)
      expect(parsed.ey).to eq(50)
      expect(parsed.edge).to eq(4)
    end

    it "extracts label boxes by EA role name" do
      parsed = described_class.parse(geom)
      expect(parsed.label_boxes).to have_key(:llb)
      llb = parsed.label_boxes[:llb]
      expect(llb.cx).to eq(19)
      expect(llb.cy).to eq(16)
      expect(llb.ox).to eq(-50)
      expect(llb.oy).to eq(-34)
    end

    it "ignores empty label slots" do
      parsed = described_class.parse(geom)
      expect(parsed.label_boxes).not_to have_key(:llt)
      expect(parsed.label_boxes).not_to have_key(:lrt)
    end
  end

  describe ".parse with nil or empty input" do
    it "returns empty Placement for nil" do
      parsed = described_class.parse(nil)
      expect(parsed.left).to be_nil
      expect(parsed.right).to be_nil
    end

    it "returns empty Placement for empty string" do
      parsed = described_class.parse("")
      expect(parsed.left).to be_nil
    end
  end
end
