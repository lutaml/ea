# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::XmlEscape do
  describe ".call" do
    it "escapes ampersands" do
      expect(described_class.call("a&b")).to eq("a&amp;b")
    end

    it "escapes less-than" do
      expect(described_class.call("a<b")).to eq("a&lt;b")
    end

    it "escapes greater-than" do
      expect(described_class.call("a>b")).to eq("a&gt;b")
    end

    it "escapes double quotes" do
      expect(described_class.call('a"b')).to eq("a&quot;b")
    end

    it "escapes all four special chars together" do
      expect(described_class.call('<a href="x">A & B</a>'))
        .to eq("&lt;a href=&quot;x&quot;&gt;A &amp; B&lt;/a&gt;")
    end

    it "handles nil by converting to empty string" do
      expect(described_class.call(nil)).to eq("")
    end

    it "handles integers by converting to string" do
      expect(described_class.call(42)).to eq("42")
    end

    it "does not double-escape existing entities" do
      expect(described_class.call("&amp;")).to eq("&amp;amp;")
    end
  end
end
