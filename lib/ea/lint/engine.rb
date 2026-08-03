# frozen_string_literal: true

module Ea
  module Lint
    # Runs all registered rules against a model and collects offenses.
    # Adding a rule = adding it to DEFAULT_RULES (OCP).
    class Engine
      attr_reader :rules

      DEFAULT_RULES = [
        Rules::NamingConventionRule,
        Rules::OrphanElementRule,
        Rules::DuplicateNameRule,
        Rules::CyclicGeneralizationRule,
        Rules::MissingStereotypeRule
      ].freeze

      # @param rules [Array<Class>] LintRule subclasses
      def initialize(rules: DEFAULT_RULES)
        @rules = rules
      end

      # @param model [#collections]
      # @return [Array<Offense>]
      def run(model)
        @rules.flat_map { |rule_class| rule_class.new.check(model) }
      end
    end
  end
end
