# frozen_string_literal: true

require "spec_helper"
require "ea/cli"

RSpec.describe Ea::Cli::Command::Parse do
  let(:qea_path) { fixtures_path("basic.qea") }

  it "emits YAML by default" do
    output = capture_stdout do
      described_class.new(file: qea_path).call
    end
    expect(output).to start_with("---")
    expect(output).to include("name:")
  end

  it "emits JSON when --format json" do
    output = capture_stdout do
      described_class.new(file: qea_path, format: "json").call
    end
    parsed = JSON.parse(output)
    expect(parsed).to be_a(Hash)
    expect(parsed).to include("name")
  end

  it "raises on unknown format" do
    expect {
      described_class.new(file: qea_path, format: "bogus").call
    }.to raise_error(Ea::Cli::Error, /Unknown format/)
  end

  it "raises FileNotFound for missing files" do
    expect {
      described_class.new(file: "/no/such.qea").call
    }.to raise_error(Ea::Cli::FileNotFound)
  end
end
