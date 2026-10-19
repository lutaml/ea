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

    it "stacks operations by (size + 6) line height" do
      ops = [build_op(name: "a"), build_op(name: "b"), build_op(name: "c")]
      svg = described_class.render(ops, bounds: bounds, first_y: 50,
                                     family: "Carlito", size: 7)
      texts = Nokogiri::XML("<svg>#{svg}</svg>").css("text")
      # Each op produces 2 text elements; op index 1 is at y = 50 + (7+6) = 63
      expect(texts[2]["y"].to_i).to eq(63)
      expect(texts[4]["y"].to_i).to eq(76)
    end

    it "returns an empty group when operations list is empty" do
      svg = described_class.render([], bounds: bounds, first_y: 50,
                                     family: "Carlito", size: 7)
      expect(Nokogiri::XML("<svg>#{svg}</svg>").css("text").size).to eq(0)
    end

    it "centers the reception heading using its emitted text length" do
      bounds = Ea::Model::Bounds.new(x: 12, y: 20, width: 125, height: 80)
      operation = build_op(is_reception: true)
      settings = [
        { family: "Cambria", size: 7 },
        { family: "Cambria", size: 7, size_unit: "pt" },
        { family: "Carlito", size: 11 },
        { family: "Liberation Sans", size: 9, size_unit: "pt", logical_height: 12 },
        { family: "Cambria", size: 7, size_unit: "px", logical_height: 12 }
      ]

      settings.each do |font|
        svg = described_class.render([operation], bounds: bounds, first_y: 50, **font)
        heading = Nokogiri::XML("<svg>#{svg}</svg>").at_css("text")
        emitted_width = heading["textLength"].to_f
        center = heading["x"].to_f + emitted_width / 2

        expect(center).to be_within(0.01).of(bounds.x + bounds.width / 2.0)
      end
    end

    it "preserves heading baseline and operation rows when receptions are present" do
      operations = [build_op(is_reception: true), build_op(name: "next")]
      svg = described_class.render(operations, bounds: bounds, first_y: 50, family: "Carlito", size: 7)
      texts = Nokogiri::XML("<svg>#{svg}</svg>").css("text")

      expect(texts[0]["y"].to_f).to eq(50)
      expect(texts[1]["y"].to_f).to eq(63)
      expect(texts[3]["y"].to_f).to eq(76)
    end
  end

  describe ".operation_text" do
    it "renders name + params + return type" do
      op = build_op(name: "draw")
      op.parameters = []
      op.return_type_name = "void"
      text = described_class.operation_text( op)
      expect(text).to eq("draw(): void")
    end

    it "omits the return type clause when none" do
      op = build_op(name: "draw")
      op.parameters = []
      op.return_type_name = nil
      text = described_class.operation_text( op)
      expect(text).to eq("draw()")
    end

    it "renders in-params named and inout params as type with star" do
      op = build_op(name: "resize")
      p1 = Ea::Model::Parameter.new(name: "w", type_name: "int")
      p2 = Ea::Model::Parameter.new(name: "h", type_name: "int", direction: "inout")
      op.parameters = [p1, p2]
      op.return_type_name = "void"
      text = described_class.operation_text(op)
      expect(text).to eq("resize(w: int, int*): void")
    end
  end
end
