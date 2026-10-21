# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Phantom connector ends without their own role" do
  include PhantomEmptyEndHelpers

  let(:phantom) { { lwidth: "1", phantom_outline: true } }

  it "does not copy the populated source onto the anonymous target" do
    expect(end_texts(:target, style: phantom, roles: ["boundedBy", nil])).to eq([])
  end

  it "does not copy the populated target onto the anonymous source" do
    expect(end_texts(:source, style: phantom, roles: [nil, "owner"])).to eq([])
  end

  it "keeps the populated source end" do
    expect(end_texts(:source, style: phantom, roles: ["boundedBy", nil])).to eq(["+boundedBy", "0..*"])
  end

  it "keeps the own stereotype of an anonymous end" do
    expect(end_texts(:target, style: phantom, roles: ["boundedBy", nil], target_stereotype: "property"))
      .to eq(["«property»"])
  end
end

RSpec.describe "Connectors with two populated ends or no phantom outline" do
  include PhantomEmptyEndHelpers

  let(:phantom) { { lwidth: "1", phantom_outline: true } }

  it "renders both ends of a phantom with two populated ends" do
    expect([end_texts(:source, style: phantom, roles: %w[a b]), end_texts(:target, style: phantom, roles: %w[a b])])
      .to eq([["+a", "0..*"], ["+b", "1"]])
  end

  it "still falls back to the opposite end on a non-phantom connector" do
    expect(end_texts(:target, style: { lwidth: "1" }, roles: ["boundedBy", nil])).to eq(["+boundedBy", "0..*"])
  end
end
