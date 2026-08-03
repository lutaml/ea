# frozen_string_literal: true

module Ea
  module Lint
    # Default namespace for built-in lint rules.
    module Rules
      autoload :NamingConventionRule, "ea/lint/rules/naming_convention"
      autoload :OrphanElementRule, "ea/lint/rules/orphan_element"
      autoload :DuplicateNameRule, "ea/lint/rules/duplicate_name"
      autoload :CyclicGeneralizationRule, "ea/lint/rules/cyclic_generalization"
      autoload :MissingStereotypeRule, "ea/lint/rules/missing_stereotype"
    end
  end
end
