# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  describe "#parse_label_boxes (per-label styling)" do
    let(:db) { Ea.parse("examples/qea/basic.qea") }
    let(:builder) do
      # Reach the private method via a tiny stub instance that has
      # the database context but no full build_one cycle. Tests only
      # the parser, not the diagram pipeline.
      described_class.new(db)
    end

    def parse(geometry_str)
      builder.parse_label_boxes(geometry_str)
    end

    it "parses all 12 styling fields from a label box" do
      geom = "SX=5;SY=38;EX=5;EY=32;EDGE=2;" \
             "$LLB=CX=24:CY=13:OX=-42:OY=-1:HDN=0:BLD=1:ITA=0:" \
             "UND=0:CLR=-1:ALN=1:DIR=0:ROT=0;"
      box = parse(geom)[:llb]

      expect(box).not_to be_nil
      expect(box["ox"]).to eq(-42)
      expect(box["oy"]).to eq(-1)
      expect(box["cx"]).to eq(24)
      expect(box["cy"]).to eq(13)
      expect(box["hidden"]).to eq(false)
      expect(box["bold"]).to eq(true)
      expect(box["italic"]).to eq(false)
      expect(box["underline"]).to eq(false)
      expect(box["color"]).to eq(-1)
      expect(box["alignment"]).to eq(1)
      expect(box["direction"]).to eq(0)
      expect(box["rotation"]).to eq(0)
    end

    it "parses multiple label boxes in one geometry string" do
      geom = "EDGE=1;$LLB=CX=16:CY=13:OX=0:OY=0:HDN=0:BLD=0:ITA=0:" \
             "UND=0:CLR=-1:ALN=0:DIR=0:ROT=0;" \
             "LLT=CX=74:CY=13:OX=0:OY=0:HDN=0:BLD=0:ITA=0:" \
             "UND=0:CLR=-1:ALN=0:DIR=0:ROT=0;"
      boxes = parse(geom)

      expect(boxes[:llb]).not_to be_nil
      expect(boxes[:llt]).not_to be_nil
      expect(boxes[:llb]["ox"]).to eq(0)
      expect(boxes[:llt]["cx"]).to eq(74)
    end

    it "returns HDN=1 as hidden=true" do
      geom = "$LLB=CX=16:CY=13:OX=0:OY=0:HDN=1:BLD=0:ITA=0:" \
             "UND=0:CLR=-1:ALN=0:DIR=0:ROT=0;"
      expect(parse(geom)[:llb]["hidden"]).to eq(true)
    end

    it "omits a label box when OX/OY are absent" do
      geom = "$LLB=;LLT=CX=10:CY=10:OX=1:OY=1:HDN=0:BLD=0:ITA=0:" \
             "UND=0:CLR=-1:ALN=0:DIR=0:ROT=0;"
      boxes = parse(geom)
      expect(boxes[:llb]).to be_nil
      expect(boxes[:llt]).not_to be_nil
    end

    it "returns empty hash when no label boxes present" do
      expect(parse("SX=0;SY=0;EX=10;EY=10;EDGE=1;")).to eq({})
    end

    it "handles negative rotation" do
      geom = "$LLB=CX=16:CY=13:OX=0:OY=0:HDN=0:BLD=0:ITA=0:" \
             "UND=0:CLR=-1:ALN=0:DIR=0:ROT=-45;"
      expect(parse(geom)[:llb]["rotation"]).to eq(-45)
    end
  end
end
