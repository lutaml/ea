# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/element/operation_renderer"

RSpec.describe Ea::Svg::EaEmitter::Element::OperationRenderer do
  let(:bounds) { Ea::Model::Bounds.new(x: 10, y: 20, width: 100, height: 80) }

  def build_op(attrs = {})
    defaults = { name: "doIt", visibility: "public" }
    Ea::Model::Operation.new(defaults.merge(attrs))
  end

  describe ".render" do
    it "returns a <g> wrapping one operation as two <text> elements" do
      ops = [build_op]
      svg = described_class.render(ops, bounds: bounds, first_y: 50,
                                     family: "Carlito", size: 7)
      texts = Nokogiri::XML("<svg>#{svg}</svg>").css("text")
      expect(texts.size).to eq(2)
    end

    it "emits the visibility marker and content text at correct x offsets" do
      ops = [build_op(name: "draw")]
      svg = described_class.render(ops, bounds: bounds, first_y: 50,
                                     family: "Carlito", size: 7)
      texts = Nokogiri::XML("<svg>#{svg}</svg>").css("text")
      # First text at visibility offset (5), second at content offset (20)
      expect(texts[0]["x"].to_i).to eq(10 + described_class::VISIBILITY_X_OFFSET)
      expect(texts[1]["x"].to_i).to eq(10 + described_class::CONTENT_X_OFFSET)
    end

    it "stacks operations by (size + 4) line height" do
      ops = [build_op(name: "a"), build_op(name: "b"), build_op(name: "c")]
      svg = described_class.render(ops, bounds: bounds, first_y: 50,
                                     family: "Carlito", size: 7)
      texts = Nokogiri::XML("<svg>#{svg}</svg>").css("text")
      # Each op produces 2 text elements; op index 1 is at y = 50 + (7+4) = 61
      expect(texts[2]["y"].to_i).to eq(61)
      expect(texts[4]["y"].to_i).to eq(72)
    end

    it "returns an empty group when operations list is empty" do
      svg = described_class.render([], bounds: bounds, first_y: 50,
                                     family: "Carlito", size: 7)
      expect(Nokogiri::XML("<svg>#{svg}</svg>").css("text").size).to eq(0)
    end
  end

  describe ".operation_text" do
    it "renders name + params + return type" do
      op = build_op(name: "draw")
      op.parameters = []
      op.return_type_name = "void"
      text = described_class.send(:operation_text, op)
      expect(text).to eq("draw(): void")
    end

    it "omits the return type clause when none" do
      op = build_op(name: "draw")
      op.parameters = []
      op.return_type_name = nil
      text = described_class.send(:operation_text, op)
      expect(text).to eq("draw()")
    end

    it "joins parameter type names with commas (no param names)" do
      op = build_op(name: "resize")
      p1 = Ea::Model::Parameter.new(name: "w", type_name: "int")
      p2 = Ea::Model::Parameter.new(name: "h", type_name: "int")
      op.parameters = [p1, p2]
      op.return_type_name = "void"
      text = described_class.send(:operation_text, op)
      expect(text).to eq("resize(int, int): void")
    end
  end
end
