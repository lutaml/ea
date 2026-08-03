# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Document do
  describe "#emit_images" do
    let(:diagram) { Ea::Model::Diagram.new(id: "d1", name: "D") }

    # Struct subclass matching Document's expected API: responds to
    # #collections (a hash). Different from Struct.new's auto-kwargs.
    class FakeDoc
      attr_reader :collections

      def initialize(collections)
        @collections = collections
      end
    end

    it "returns nil when document is nil" do
      emitter = described_class.new(diagram, model_index: {})
      expect(emitter.send(:emit_images)).to be_nil
    end

    it "returns nil when document is not an Ea::Qea::Database" do
      doc = FakeDoc.new({})
      emitter = described_class.new(diagram, model_index: {}, document: doc)
      expect(emitter.send(:emit_images)).to be_nil
    end

    it "emits <g id=images> when Ea::Qea::Database carries images + EmfRenderer returns svg" do
      # Construct a minimal Database-like object that is_a?(Ea::Qea::Database).
      image = Struct.new(:bytes).new("fake-bytes")
      db = Ea::Qea::Database.allocate
      allow(db).to receive(:collections).and_return(images: [image])

      emitter = described_class.new(diagram, model_index: {}, document: db)
      allow(Ea::Image::EmfRenderer).to receive(:render).and_return("<rect/>")

      result = emitter.send(:emit_images)
      expect(result).to include("<g id=\"images\">")
      expect(result).to include("<rect/>")
    end

    it "returns nil when EmfRenderer returns nil for all images" do
      image = Struct.new(:bytes).new("fake-bytes")
      db = Ea::Qea::Database.allocate
      allow(db).to receive(:collections).and_return(images: [image])

      emitter = described_class.new(diagram, model_index: {}, document: db)
      allow(Ea::Image::EmfRenderer).to receive(:render).and_return(nil)

      expect(emitter.send(:emit_images)).to be_nil
    end
  end
end
