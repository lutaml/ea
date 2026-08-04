# frozen_string_literal: true

# frozen_string: true

module Ea
  # Top-level validation namespace. Hosts cross-cutting validators
  # that span multiple subsystems (QEA + XMI, lint rules, OCL).
  #
  # Distinct from Ea::Qea::Validation which is specific to QEA
  # database + UML document structural validation.
  module Validation
    autoload :XmiParity, "ea/validation/xmi_parity"
  end
end
