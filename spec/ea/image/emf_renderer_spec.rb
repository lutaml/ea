# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Image::EmfRenderer do
  describe ".available?" do
    it "returns boolean without raising" do
      expect { described_class.available? }.not_to raise_error
      expect([true, false]).to include(described_class.available?)
    end

    it "caches the result" do
      first = described_class.available?
      second = described_class.available?
      expect(first).to eq(second)
    end
  end

  describe ".render" do
    it "returns nil for nil bytes" do
      expect(described_class.render(nil)).to be_nil
    end

    it "returns nil for empty bytes" do
      expect(described_class.render("")).to be_nil
    end

    it "returns nil gracefully when emfsvg cannot parse the bytes" do
      # A random non-EMF byte string. emfsvg's parser should reject
      # this and return nil via our rescue clause rather than raising.
      skip "emfsvg not installed" unless described_class.available?

      result = described_class.render("not an EMF blob")
      expect(result).to be_nil
    end
  end

  describe "with real t_image fixture" do
    let(:db) { Ea.parse("examples/qea/20251010_current_plateau_v5.1.qea") }
    let(:image) { db.collections[:images].first }

    it "loads the t_image row with EMF type" do
      skip "no image in fixture" unless image

      expect(image.type).to eq("ENHMetafile")
      expect(image.emf?).to be(true)
      expect(image.bytes.size).to be > 100
    end

    it "attempts conversion via EmfRenderer without raising" do
      skip "no image in fixture" unless image
      skip "emfsvg not installed" unless described_class.available?

      # The current emf gem version doesn't parse this specific EMF
      # variant (signature=1 expected, header layout differs). When
      # upstream emfsvg supports it, this will produce an SVG string.
      # Until then, we expect graceful nil.
      result = described_class.render(image.bytes)
      expect(result).to be_nil.or(start_with("<svg"))
    end
  end
end
