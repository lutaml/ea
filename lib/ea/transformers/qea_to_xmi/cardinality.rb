# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Pure-function cardinality / multiplicity parser for EA's
      # free-text bound fields (`t_attribute.upperbound`,
      # `t_connector.sourcecard`, etc.).
      #
      # EA stores cardinality as opaque strings: `1`, `0..1`, `1..*`,
      # `*`, occasionally `unbounded` or `*-1`. The XMI wire form needs
      # two separate child elements (`<lowerValue value="N"/>` and
      # `<upperValue value="M"/>`) — never a range string. This module
      # translates the EA form to a `{ lower:, upper: }` pair.
      #
      # Default-when-empty: EA's "no bound specified" maps to UML's
      # unspecified multiplicity, which Sparx renders as
      # `<lowerValue value="0"/>` and `<upperValue value="-1"/>`.
      # Always emitting both is required for round-trip parity with
      # real Sparx XMI (see TODO 26).
      module Cardinality
        # Tokens EA uses for "unbounded". Matched case-insensitively.
        UNLIMITED_TOKENS = %w[* *-1 unbounded].freeze

        # UML defaults when EA carries no explicit bound.
        DEFAULT_LOWER = "0"
        DEFAULT_UPPER = "-1"

        module_function

        # @param raw [String, nil] e.g. "1..*", "0..1", "1", "*", nil
        # @return [Hash{Symbol=>String}] `{ lower:, upper: }` always
        #   populated; never nil. Empty/nil input returns the UML default.
        def parse(raw)
          return defaults if raw.nil? || raw.to_s.strip.empty?

          stripped = raw.to_s.strip
          return parse_range(stripped) if stripped.include?("..")

          # Bare unlimited token (e.g. "*") means "many" — lower bound
          # is unspecified, which UML renders as 0..-1. Returning
          # `{ lower: "-1", upper: "-1" }` here would be invalid:
          # LiteralInteger cannot hold -1.
          return defaults if UNLIMITED_TOKENS.include?(stripped.downcase)

          single = normalize_bound(stripped)
          { lower: single, upper: single }
        end

        # Normalise an upper-bound token: `*` / `unbounded` → `-1`
        # (UML LiteralUnlimitedNatural wire form).
        # @param raw [String, Integer, nil]
        # @return [String]
        def normalize_upper(raw)
          return DEFAULT_UPPER if raw.nil?

          stripped = raw.to_s.strip
          return DEFAULT_UPPER if stripped.empty?

          UNLIMITED_TOKENS.include?(stripped.downcase) ? "-1" : stripped
        end

        # Normalise a lower-bound token: empty/nil → "0" (UML default).
        # @param raw [String, Integer, nil]
        # @return [String]
        def normalize_lower(raw)
          return DEFAULT_LOWER if raw.nil?

          stripped = raw.to_s.strip
          stripped.empty? ? DEFAULT_LOWER : stripped
        end

        # ---- Internal helpers ----

        def defaults
          { lower: DEFAULT_LOWER, upper: DEFAULT_UPPER }
        end

        def parse_range(stripped)
          lower, upper = stripped.split("..", 2)
          { lower: normalize_bound(lower), upper: normalize_bound(upper) }
        end

        # A single bound token (one side of `..` or a bare scalar).
        # Empty / `*` → UML unlimited (`-1`).
        def normalize_bound(token)
          return "-1" if token.nil?
          return "-1" if token.strip.empty?

          stripped = token.strip
          UNLIMITED_TOKENS.include?(stripped.downcase) ? "-1" : stripped
        end
      end
    end
  end
end
