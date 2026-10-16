# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA diagrams with NoFullScope" do
  include QeaContentHelpers

  let(:document) { Ea::Sources::Qea::Adapter.from_path("examples/qea/basic.qea") }

  it "names nested classes without the owner qualifier when NoFullScope=1" do
    texts = qea_texts(document, "372F7F7B")

    expect(texts).to include("Class A.1", "Class A.4.3")
    expect(texts).not_to include("Class A::Class A.1", "Class A.4::Class A.4.3")
  end

  it "keeps the owner qualifier when NoFullScope is absent" do
    expect(qea_texts(document, "6D0349D5")).to include("Class B::Class B.1")
  end
end
