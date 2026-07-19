# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Normalizes XMI identifiers (xmi:id strings, often EAID_...
      # or GUID-shaped) into stable model ids. Pass-through for
      # real ids; synthetic ids for derived elements that have no
      # xmi:id (annotations, waypoints).
      module IdNormalizer
        module_function

        def from_xmi_id(xmi_id)
          return nil if xmi_id.nil? || xmi_id.empty?

          xmi_id.to_s
        end

        def synthetic_id(owner_id, kind, suffix = nil)
          parts = ["#{owner_id}:#{kind}"]
          parts << suffix if suffix
          parts.join(":")
        end
      end
    end
  end
end
