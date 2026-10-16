# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA instance specification alias" do
  include QeaContentHelpers

  let(:document) { Ea::Sources::Qea::Adapter.from_path("examples/qea/basic.qea") }

  it "labels an aliased instance as Name / alias: Classifier" do
    texts = qea_texts(document, "14E9F5FD")

    expect(texts).to include("Object 01 / roleOne: Class A", "Object 05 / roleThree3: Class C")
    expect(texts).not_to include("Object 01: Class A")
  end

  it "keeps the plain name when the instance has no alias" do
    expect(qea_texts(document, "D14AA320")).to include("Object A", "Object B")
  end
end
