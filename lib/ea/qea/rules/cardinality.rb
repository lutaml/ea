# frozen_string_literal: true

module Ea
  module Qea
    module Rules
      # Canonical cardinality / multiplicity parser for EA's free-text
      # bound fields (t_attribute.upperbound / lowerbound,
      # t_connector.sourcecard, etc.).
      #
      # EA stores cardinality as opaque strings: `1`, `0..1`, `*`,
      # occasionally `unbounded` or `*-1`. The canonical form is the
      # `{ min:, max: }` pair with the UML conventions: unlimited tokens
      # mean 0..*, a bare value means N..N, and blank means unspecified
      # (0..*).
      module Cardinality
        # Tokens EA uses for "unbounded". Matched case-insensitively.
        UNLIMITED_TOKENS = %w[* *-1 -1 unbounded].freeze

        # UML defaults when EA carries no explicit bound.
        DEFAULT_MIN = "0"
        DEFAULT_MAX = "*"

        module_function

        # @param raw [String, nil] e.g. "1..*", "0..1", "1", "*", nil
        # @return [Hash{Symbol=>String}] `{ min:, max: }` always
        #   populated; nil/blank input returns the UML default 0..*.
        def parse(raw)
          return defaults if raw.nil? || raw.to_s.strip.empty?

          stripped = raw.to_s.strip
          return parse_range(stripped) if stripped.include?("..")

          # Bare unlimited token (e.g. "*") means "many" — 0..*.
          return defaults if UNLIMITED_TOKENS.include?(stripped.downcase)

          { min: stripped, max: stripped }
        end

        # Normalise a max-bound token: `*` / `unbounded` → `*`.
        # @param raw [String, Integer, nil]
        # @return [String]
        def normalize_max(raw)
          return DEFAULT_MAX if raw.nil?

          stripped = raw.to_s.strip
          return DEFAULT_MAX if stripped.empty?

          UNLIMITED_TOKENS.include?(stripped.downcase) ? "*" : stripped
        end

        # Normalise a min-bound token: empty/nil → "0" (UML default).
        # Unlimited tokens also → "0" — a lower bound cannot hold `*`.
        # @param raw [String, Integer, nil]
        # @return [String]
        def normalize_min(raw)
          return DEFAULT_MIN if raw.nil?

          stripped = raw.to_s.strip
          return DEFAULT_MIN if stripped.empty?

          UNLIMITED_TOKENS.include?(stripped.downcase) ? DEFAULT_MIN : stripped
        end

        # ---- Internal helpers ----

        def defaults
          { min: DEFAULT_MIN, max: DEFAULT_MAX }
        end

        def parse_range(stripped)
          min, max = stripped.split("..", 2)
          { min: normalize_min(min), max: normalize_max(max) }
        end
      end
    end
  end
end
