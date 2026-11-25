# frozen_string_literal: true

module Ea
  module Qea
    module Rules
      # Canonical EA scope → visibility token mapping.
      #
      # QEA stores scope as text ("Public", "Private", "Protected",
      # "Package") in t_attribute.Scope / t_operation.Scope /
      # t_object.Scope. Matching is case-insensitive; unrecognised or
      # blank values default to "public".
      module Visibility
        TOKENS = %w[public private protected package].freeze
        DEFAULT = "public"

        # Extension-property wire form: EA's own XMI exports carry the
        # capitalized form ("Public") in <properties scope="...">.
        module_function

        # @param scope [String, Symbol, nil] EA scope text
        # @return [String] the canonical lowercase token, "public" default
        def canonical(scope)
          token = scope.to_s.strip.downcase
          TOKENS.include?(token) ? token : DEFAULT
        end

        # @param scope [String, Symbol, nil] EA scope text
        # @return [String] capitalized wire form, "Public" default
        def extension_scope(scope)
          canonical(scope).capitalize
        end
      end
    end
  end
end
