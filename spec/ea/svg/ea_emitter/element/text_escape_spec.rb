# frozen_string: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/element/text_escape"

RSpec.describe Ea::Svg::EaEmitter::Element::TextEscape do
  describe ".call" do
    it "returns empty string for nil" do
      expect(described_class.call(nil)).to eq("")
    end

    it "returns empty string for empty input" do
      expect(described_class.call("")).to eq("")
    end

    it "escapes ampersand" do
      expect(described_class.call("a & b")).to eq("a &amp; b")
    end

    it "escapes less-than" do
      expect(described_class.call("a < b")).to eq("a &lt; b")
    end

    it "escapes greater-than" do
      expect(described_class.call("a > b")).to eq("a &gt; b")
    end

    it "escapes double quotes" do
      expect(described_class.call(%(a "b" c))).to eq("a &quot;b&quot; c")
    end

    it "escapes multiple characters in one pass" do
      expect(described_class.call(%(<a href="x">&</a>))).to eq("&lt;a href=&quot;x&quot;&gt;&amp;&lt;/a&gt;")
    end

    it "preserves non-ASCII characters (UTF-8)" do
      expect(described_class.call("日本語")).to eq("日本語")
    end

    it "coerces non-string input via to_s" do
      expect(described_class.call(42)).to eq("42")
    end

    it "preserves the «» stereotype markers" do
      expect(described_class.call("«FeatureType»")).to eq("«FeatureType»")
    end

    it "preserves the :: namespace separator" do
      expect(described_class.call("pkg::Klass")).to eq("pkg::Klass")
    end
  end
end
