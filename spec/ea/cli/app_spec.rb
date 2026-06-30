# frozen_string_literal: true

require "spec_helper"
require "ea/cli"

RSpec.describe Ea::Cli::App do
  describe "#version" do
    it "prints the gem version" do
      output = capture_stdout { described_class.start(%w[version]) }
      expect(output.strip).to eq(Ea::VERSION)
    end
  end

  describe "#help" do
    it "lists all commands" do
      output = capture_stdout { described_class.start(%w[help]) }
      %w[list diagrams validate stats parse convert version].each do |cmd|
        expect(output).to include(cmd)
      end
    end
  end
end
