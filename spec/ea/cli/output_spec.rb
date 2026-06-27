# frozen_string_literal: true

require "spec_helper"
require "ea/cli/output"

RSpec.describe Ea::Cli::Output do
  describe ".for" do
    it "returns the registered formatter class for known names" do
      expect(described_class.for(:table)).to eq(Ea::Cli::Output::TableFormatter)
      expect(described_class.for(:json)).to eq(Ea::Cli::Output::JsonFormatter)
      expect(described_class.for(:yaml)).to eq(Ea::Cli::Output::YamlFormatter)
    end

    it "raises ArgumentError for unknown names with a list of registered ones" do
      expect {
        described_class.for(:bogus)
      }.to raise_error(ArgumentError, /No output formatter 'bogus'/)
    end
  end

  describe ".instance_for" do
    it "returns a fresh instance of the named formatter" do
      instance = described_class.instance_for(:table)
      expect(instance).to be_a(Ea::Cli::Output::TableFormatter)
    end
  end

  describe ".registered_formats" do
    it "includes the built-in formatters" do
      expect(described_class.registered_formats).to include(:table, :json, :yaml)
    end
  end

  describe ".register" do
    it "allows new formatters to be added (OCP)" do
      custom = Class.new(Ea::Cli::Output::Formatter) do
        def render(rows, columns: []); end
      end
      described_class.register(:custom_test, custom)
      expect(described_class.for(:custom_test)).to eq(custom)
    end
  end
end
