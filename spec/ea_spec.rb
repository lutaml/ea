# frozen_string_literal: true

RSpec.describe Ea do
  it "has a version number" do
    expect(Ea::VERSION).not_to be nil
  end

  it "loads QEA, Diagram, and Transformations modules" do
    expect(defined?(Ea::Qea)).to eq("constant")
    expect(defined?(Ea::Diagram)).to eq("constant")
    expect(defined?(Ea::Transformations)).to eq("constant")
  end

  it "loads Transformers module" do
    expect(defined?(Ea::Transformers)).to eq("constant")
  end
end
