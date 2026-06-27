# frozen_string_literal: true

require "spec_helper"
require "ea/cli"

RSpec.describe Ea::Cli::Command::Validate do
  let(:qea_path) { fixtures_path("basic.qea") }

  it "emits a table of validation messages" do
    output = capture_stdout do
      described_class.new(file: qea_path, format: "table").call
    rescue SystemExit
      # validate exits 1 when errors are found — that is expected for this
      # fixture (info messages about unreferenced objects).
    end
    expect(output).to include("severity")
    expect(output).to include("entity_type")
    expect(output).to include("message")
  end

  it "raises FileNotFound for missing files" do
    expect {
      described_class.new(file: "/no/such.qea").call
    }.to raise_error(Ea::Cli::FileNotFound)
  end
end
