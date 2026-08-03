# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Document do
  describe "#emit_images" do
    let(:diagram) { Ea::Model::Diagram.new(id: "d1", name: "D") }

    it "returns nil when document is nil" do
      emitter = described_class.new(diagram, model_index: {})
      expect(emitter.emit_images).to be_nil
    end

    it "returns nil when document is not an Ea::Qea::Database" do
      doc = Struct.new(:collections).new({})
      emitter = described_class.new(diagram, model_index: {}, document: doc)
      expect(emitter.emit_images).to be_nil
    end

    it "emits <g id=images> when Ea::Qea::Database carries images + EmfRenderer returns svg" do
      image = Struct.new(:bytes).new("fake-bytes")
      db = Ea::Qea::Database.new("test.qea")
      db.add_collection(:images, [image])
      emitter = described_class.new(diagram, model_index: {}, document: db)

      stub_const("Ea::Image::EmfRenderer", Class.new do
        def self.render(_bytes)
          "<rect/>"
        end
      end)

      result = emitter.emit_images
      expect(result).to include("<g id=\"images\">")
      expect(result).to include("<rect/>")
    end

    it "returns nil when EmfRenderer returns nil for all images" do
      image = Struct.new(:bytes).new("fake-bytes")
      db = Ea::Qea::Database.new("test.qea")
      db.add_collection(:images, [image])
      emitter = described_class.new(diagram, model_index: {}, document: db)

      stub_const("Ea::Image::EmfRenderer", Class.new do
        def self.render(_bytes)
          nil
        end
      end)

      expect(emitter.emit_images).to be_nil
    end
  end
end
