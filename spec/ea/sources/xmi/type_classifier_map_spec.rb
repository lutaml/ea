# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Sources::Xmi::TypeClassifierMap do
  it "maps uml:Signal to Signal" do
    expect(described_class.class_for("uml:Signal")).to eq(Ea::Model::Signal)
  end

  it "keeps the existing mappings" do
    expect(described_class.class_for("uml:Class")).to eq(Ea::Model::Klass)
  end

  it "builds the three signals of basic.xmi as Signal classifiers" do
    document = Ea::Sources::Xmi::Adapter.from_path(fixtures_path("basic.xmi"))
    signals = document.classifiers.grep(Ea::Model::Signal)

    expect(signals.map(&:name)).to eq(["Signal A", "Signal B", "Signal C"])
    expect(document.classifiers.grep(Ea::Model::Klass).size).to eq(65)
  end

  it "builds the nested classes of both basic.xmi hierarchies as Klass classifiers" do
    document = Ea::Sources::Xmi::Adapter.from_path(fixtures_path("basic.xmi"))
    nested = document.classifiers.grep(Ea::Model::Klass).map(&:name).grep(/\AClass A\.\d/)

    expect(nested.size).to eq(32)
    expect(nested.tally.values.uniq).to eq([2])
  end
end
