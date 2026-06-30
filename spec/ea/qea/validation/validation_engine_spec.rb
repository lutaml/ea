# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Qea::Validation::ValidationEngine do
  let(:document) { Lutaml::Uml::Document.new }
  let(:database) { Ea::Qea::Database.new("test.qea") }

  describe "#initialize" do
    it "creates an engine with document and database", :aggregate_failures do
      engine = described_class.new(document, database: database)

      expect(engine.document).to eq(document)
      expect(engine.database).to eq(database)
      expect(engine.registry).to be_a(Ea::Qea::Validation::ValidatorRegistry)
    end

    it "sets up default validators", :aggregate_failures do
      engine = described_class.new(document, database: database)

      expect(engine.registry.registered?(:package)).to be true
      expect(engine.registry.registered?(:class)).to be true
      expect(engine.registry.registered?(:attribute)).to be true
      expect(engine.registry.registered?(:operation)).to be true
      expect(engine.registry.registered?(:association)).to be true
    end
  end

  describe "#validate" do
    let(:engine) { described_class.new(document, database: database) }

    it "returns a ValidationResult" do
      result = engine.validate
      expect(result).to be_a(Ea::Qea::Validation::ValidationResult)
    end

    it "runs only specified validators" do
      result = engine.validate(validators: %i[package class])
      expect(result).to be_a(Ea::Qea::Validation::ValidationResult)
    end

    context "with an empty document and database" do
      it "reports no errors" do
        result = engine.validate
        expect(result).to be_a(Ea::Qea::Validation::ValidationResult)
      end
    end
  end

  describe "#valid?" do
    let(:engine) { described_class.new(document, database: database) }

    it "returns true when no errors" do
      expect(engine.valid?).to be true
    end
  end

  describe "#register_validator" do
    let(:engine) { described_class.new(document, database: database) }
    let(:custom_validator) do
      Class.new(Ea::Qea::Validation::BaseValidator) do
        def validate(_context)
          Ea::Qea::Validation::ValidationResult.new
        end
      end
    end

    it "registers a custom validator" do
      engine.register_validator(:custom, custom_validator)
      expect(engine.registry.registered?(:custom)).to be true
    end
  end

  describe "#validate_and_display" do
    let(:engine) { described_class.new(document, database: database) }

    it "validates and returns result", :aggregate_failures do
      result = nil

      expect do
        result = engine.validate_and_display(formatter: :text)
      end.to output(/VALIDATION REPORT/).to_stdout

      expect(result).to be_a(Ea::Qea::Validation::ValidationResult)
    end
  end
end
