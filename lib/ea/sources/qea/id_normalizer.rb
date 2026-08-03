# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Normalizes EA's identifier formats into stable strings used
      # as Ea::Model element ids. EA represents identity as
      # `{GUID}` strings.
      #
      # Two output formats:
      # - `from_guid` — bare GUID without braces (canonical model id)
      # - `to_eaid` — `EAID_<guid with dashes-to-underscores>` matching
      #   the reference SVG filename convention
      module IdNormalizer
        module_function

        def from_guid(ea_guid)
          return nil if ea_guid.nil? || ea_guid.empty?

          ea_guid.to_s.gsub(/[{}]/, "")
        end

        # Convert a GUID to the EAID_ filename format used by EA's
        # SVG export: strip braces, replace dashes with underscores,
        # prefix with EAID_.
        def to_eaid(ea_guid)
          return nil if ea_guid.nil? || ea_guid.empty?

          "EAID_" + ea_guid.to_s.gsub(/[{}]/, "").tr("-", "_")
        end

        def synthetic(prefix, *parts)
          "#{prefix}:#{parts.join(":")}"
        end
      end
    end
  end
end

