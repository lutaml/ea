# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI diagram package-content and foreign flags" do
  include XmiDiagramFlagHelpers

  let(:xmi) { basic_diagram_flags(Ea::Sources::Xmi::Adapter, "spec/fixtures/basic.xmi") }
  let(:qea) { basic_diagram_flags(Ea::Sources::Qea::Adapter, "examples/qea/basic.qea") }

  it "turns both flags on for diagrams whose style has PackageContents=1 and HighlightForeign=1" do
    expect(xmi.count { |_name, contents, foreign| contents && foreign }).to eq(21)
  end

  it "leaves both flags off for the diagram whose style has them at 0" do
    expect(xmi.reject { |_name, contents, foreign| contents || foreign }.size).to eq(1)
  end

  it "agrees with the flags the QEA source derives per diagram" do
    expect(xmi).to match_array(qea)
  end
end
