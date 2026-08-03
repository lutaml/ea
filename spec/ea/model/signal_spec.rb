# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Model::Signal do
  it "is a Classifier" do
    expect(described_class.new).to be_a(Ea::Model::Classifier)
  end

  it "defaults model_kind to 'signal'" do
    expect(described_class.new.model_kind).to eq("signal")
  end

  it "round-trips through JSON preserving the model_kind discriminator" do
    signal = described_class.new(id: "s1", name: "Signal A")
    round_trip = described_class.from_json(signal.to_json)
    expect(round_trip).to be_a(described_class)
    expect(round_trip.name).to eq("Signal A")
  end
end

RSpec.describe Ea::Sources::Qea::ObjectClassifierMap do
  it "maps 'Signal' to Ea::Model::Signal" do
    expect(described_class.class_for("Signal")).to eq(Ea::Model::Signal)
  end

  it "maps 'Object' to Ea::Model::Klass (instance spec fallback)" do
    expect(described_class.class_for("Object")).to eq(Ea::Model::Klass)
  end

  it "emits 'signal' model_kind for 'Signal'" do
    expect(described_class.model_kind_for("Signal")).to eq("signal")
  end
end

RSpec.describe Ea::Svg::EaEmitter::Element::HeaderLines do
  it "falls back to «signal» stereotype for Signal classifiers" do
    signal = Ea::Model::Signal.new(id: "s1", name: "Sig")
    lines = described_class.for(signal)
    expect(lines).to include(["«signal»", :normal])
    expect(lines).to include(["Sig", :bold])
  end
end
