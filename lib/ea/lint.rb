# frozen_string_literal: true

module Ea
  # Model lint namespace. Each rule extends LintRule and produces
  # Offense records. New rules register in Engine without touching
  # existing rules (OCP).
  module Lint
    autoload :Engine, "ea/lint/engine"
    autoload :LintRule, "ea/lint/lint_rule"
    autoload :Offense, "ea/lint/offense"
    autoload :Rules, "ea/lint/rules"
  end
end
