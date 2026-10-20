# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI diagram show_notes" do
  include XmiShowNotesHelpers

  let(:xmi) { basic_show_notes(Ea::Sources::Xmi::Adapter, "spec/fixtures/basic.xmi") }
  let(:qea) { basic_show_notes(Ea::Sources::Qea::Adapter, "examples/qea/basic.qea") }

  it "is set on the diagram whose StyleEx has ShowNotes=1" do
    expect(xmi.select { |_name, shown| shown }.keys).to eq(["Domain Model"])
  end

  it "stays false on a diagram whose StyleEx has ShowNotes=0" do
    expect(xmi["Starter Object Diagram"]).to be(false)
  end

  it "agrees with the flag the QEA source derives per diagram" do
    expect(xmi).to eq(qea)
  end
end
