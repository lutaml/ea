# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA ordered fixed-size attributes" do
  include QeaContentHelpers

  let(:document) { Ea::Sources::Qea::Adapter.from_path("examples/qea/20251010_current_plateau_v5.1.qea") }

  it "collapses equal bounds to one count and marks the attribute ordered" do
    expect(qea_texts(document, "73025C5A")).to include("elements: xs:double [16] {ordered}")
    expect(qea_texts(document, "BC1F7E00")).to include("elements: xs:double [4] {ordered}",
                                                       "elements: xs:double [12] {ordered}")
  end

  it "leaves range multiplicities and unordered attributes unchanged" do
    texts = qea_texts(document, "BC1F7E00")

    expect(texts).to include("textureCoordinates: gml:doubleList [1..*]",
                             "preferWorldFile: xs:boolean [0..1] = true",
                             "target: xs:anyURI [0..*]")
    expect(texts.grep(/\{ordered\}/).size).to eq(2)
  end
end
