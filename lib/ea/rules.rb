# frozen_string_literal: true

module Ea
  # EA-domain semantic rules shared across input formats (QEA rows and
  # Sparx XMI). Format-specific traversal lives in Qea::Rules.
  module Rules
    autoload :GeneralAttributeMapping, "ea/rules/general_attribute_mapping"
    autoload :Namespacing, "ea/rules/namespacing"
  end
end
