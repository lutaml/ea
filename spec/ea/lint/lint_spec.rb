# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Lint::Offense do
  describe "#error?" do
    it "is true when severity is :error" do
      offense = described_class.new(rule: "r", severity: :error,
                                     entity_id: "1", entity_name: "Foo",
                                     message: "bad")
      expect(offense.error?).to be true
    end

    it "is false when severity is :warning" do
      offense = described_class.new(rule: "r", severity: :warning,
                                     entity_id: "1", entity_name: "Foo",
                                     message: "bad")
      expect(offense.error?).to be false
    end
  end

  describe "#warning?" do
    it "is true when severity is :warning" do
      offense = described_class.new(rule: "r", severity: :warning,
                                     entity_id: "1", entity_name: "Foo",
                                     message: "bad")
      expect(offense.warning?).to be true
    end

    it "is false when severity is :error" do
      offense = described_class.new(rule: "r", severity: :error,
                                     entity_id: "1", entity_name: "Foo",
                                     message: "bad")
      expect(offense.warning?).to be false
    end
  end
end

RSpec.describe Ea::Lint::LintRule do
  describe ".name" do
    it "converts CamelCase class name to snake_case rule name" do
      klass = Class.new(described_class) do
        def self.to_s
          "SomeClass::NamingConventionRule"
        end
      end
      expect(klass.name).to eq("naming_convention")
    end

    it "strips trailing 'Rule' from class name" do
      klass = Class.new(described_class) do
        def self.to_s
          "DuplicateNameRule"
        end
      end
      expect(klass.name).to eq("duplicate_name")
    end
  end

  describe ".severity" do
    it "defaults to :warning" do
      klass = Class.new(described_class)
      expect(klass.severity).to eq(:warning)
    end

    it "can be overridden per class" do
      klass = Class.new(described_class)
      klass.severity = :error
      expect(klass.severity).to eq(:error)
    end
  end

  describe "#check" do
    it "raises NotImplementedError by default" do
      rule = Class.new(described_class).new
      expect { rule.check(:any_model) }.to raise_error(NotImplementedError, /check not implemented/)
    end
  end

  describe "#offense" do
    it "builds an Offense with rule name from class" do
      klass = Class.new(described_class) do
        def self.name
          "MyRule"
        end

        def check(_model)
          [offense(entity_id: "1", entity_name: "Foo", message: "oops")]
        end
      end
      result = klass.new.check(nil)
      expect(result.first).to be_a(Ea::Lint::Offense)
      expect(result.first.rule).to eq("MyRule")
      expect(result.first.entity_id).to eq("1")
      expect(result.first.message).to eq("oops")
    end
  end
end

RSpec.describe Ea::Lint::Engine do
  let(:empty_model) do
    Struct.new(:collections).new({})
  end

  describe "#run" do
    it "returns empty array when no rules produce offenses" do
      rule = Class.new(Ea::Lint::LintRule) do
        def check(_model)
          []
        end
      end
      engine = described_class.new(rules: [rule])
      expect(engine.run(empty_model)).to eq([])
    end

    it "collects offenses from all rules" do
      rule_a = Class.new(Ea::Lint::LintRule) do
        def check(_model)
          [Ea::Lint::Offense.new(rule: "A", severity: :warning,
                                  entity_id: "1", entity_name: "x", message: "a")]
        end
      end
      rule_b = Class.new(Ea::Lint::LintRule) do
        def check(_model)
          [Ea::Lint::Offense.new(rule: "B", severity: :warning,
                                  entity_id: "2", entity_name: "y", message: "b")]
        end
      end
      engine = described_class.new(rules: [rule_a, rule_b])
      result = engine.run(empty_model)
      expect(result.size).to eq(2)
      expect(result.map(&:rule)).to contain_exactly("A", "B")
    end
  end

  describe "DEFAULT_RULES" do
    it "loads all five built-in rule classes" do
      # DEFAULT_RULES uses lazy autoload; verify by referencing the constant
      expect(described_class::DEFAULT_RULES).to be_an(Array)
      expect(described_class::DEFAULT_RULES.size).to eq(5)
    end
  end
end
