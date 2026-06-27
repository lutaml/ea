# frozen_string_literal: true

require "spec_helper"
require "ea/cli"

RSpec.describe Ea::Cli::Command::Stats do
  let(:qea_path) { fixtures_path("basic.qea") }

  it "prints collection counts" do
    output = capture_stdout do
      described_class.new(file: qea_path, format: "table").call
    end
    expect(output).to include("objects")
    expect(output).to include("attributes")
    expect(output).to include("connectors")
    expect(output).to include("packages")
    expect(output).to include("diagrams")
  end

  it "returns positive integer counts for known collections" do
    output = capture_stdout do
      described_class.new(file: qea_path, format: "table").call
    end
    # objects line should contain a number > 0 (basic.qea has 121 objects)
    expect(output).to match(/objects\s+\d+/)
    objects_line = output.lines.find { |l| l.start_with?("objects") }
    count = objects_line.scan(/\d+/).first.to_i
    expect(count).to be > 0
  end

  it "raises FileNotFound for missing files" do
    expect {
      described_class.new(file: "/no/such/file.qea").call
    }.to raise_error(Ea::Cli::FileNotFound)
  end
end
