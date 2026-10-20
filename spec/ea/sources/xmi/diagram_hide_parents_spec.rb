# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI diagram HideParents flag" do
  include XmiHideParentsHelpers

  let(:xmi) { parents_by_name(Ea::Sources::Xmi::Adapter, "fixtures/basic.xmi") }
  let(:qea) { parents_by_name(Ea::Sources::Qea::Adapter, "../examples/qea/basic.qea") }

  it "turns show_parents off for the one diagram whose style has HideParents=1" do
    expect(xmi.count { |_name, shown| !shown }).to eq(1)
  end

  it "keeps show_parents on for the 21 diagrams with HideParents=0" do
    expect(xmi.count { |_name, shown| shown }).to eq(21)
  end

  it "agrees with the flag the QEA source derives per diagram" do
    expect(xmi).to match_array(qea)
  end

  it "leaves the model's generalizations and their parent classifiers intact" do
    document = QeaBridgeCorpusHelpers.document_for(
      Ea::Sources::Xmi::Adapter, File.expand_path("../../../fixtures/basic.xmi", __dir__)
    )
    generalizations = document.relationships.grep(Ea::Model::Generalization)
    parent_ids = document.classifiers.map(&:id)
    expect(generalizations).not_to be_empty
    expect(generalizations.map(&:general_id) - parent_ids).to be_empty
  end
end

RSpec.describe "XMI HideParents ghost rendering" do
  include XmiHideParentsHelpers

  it "still draws the off-canvas parent ghost when HideParents=0" do
    expect(render_without_parent(hide_parents: false)).to eq([true, 3])
  end

  it "draws no parent ghost when HideParents=1" do
    expect(render_without_parent(hide_parents: true)).to eq([false, 0])
  end
end
