# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Xmi::Adapter, "hand-drawn diagrams" do
  let(:document) do
    QeaBridgeCorpusHelpers.document_for(described_class, File.expand_path("../../../fixtures/basic.xmi", __dir__))
  end

  it "preserves the saved hand-drawn flag on the native documentation diagram" do
    diagram = document.diagrams.find { |entry| entry.style.to_s.include?("HandDraw=1;") }

    expect(diagram).not_to be_nil
    expect(diagram.hand_draw).to be(true)
  end

  it "keeps ordinary diagrams out of hand-drawn rendering" do
    ordinary = document.diagrams.reject { |entry| entry.style.to_s.include?("HandDraw=1;") }

    expect(ordinary.size).to eq(21)
    expect(ordinary.map(&:hand_draw)).to all(be(false))
  end
end
