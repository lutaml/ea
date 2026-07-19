# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Normalizes EA's identifier formats into stable strings used
      # as Ea::Model element ids. EA represents identity as
      # `{GUID}` strings. We strip the braces to give the bare GUID.
      module IdNormalizer
        module_function

        def from_guid(ea_guid)
          return nil if ea_guid.nil? || ea_guid.empty?

          ea_guid.to_s.gsub(/[{}]/, "")
        end

        def synthetic(prefix, *parts)
          "#{prefix}:#{parts.join(":")}"
        end
      end
    end
  end
end
