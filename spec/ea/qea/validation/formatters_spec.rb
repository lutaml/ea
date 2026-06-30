# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Qea::Validation::Formatters do
  it "autoloads TextFormatter" do
    expect(described_class::TextFormatter).to be_a(Class)
  end

  it "autoloads JsonFormatter" do
    expect(described_class::JsonFormatter).to be_a(Class)
  end
end
