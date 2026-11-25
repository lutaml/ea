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
      # Default-when-empty: blank input maps to UML's unspecified
      # multiplicity, `{ lower: "0", upper: "*" }`. Whether those
      # bounds reach the document is the caller's call — EA leaves an
      # association end bare when its card field is blank.
      module Cardinality
        # Tokens EA uses for "unbounded". Matched case-insensitively.
        UNLIMITED_TOKENS = Ea::Qea::Rules::Cardinality::UNLIMITED_TOKENS

        # UML defaults when EA carries no explicit bound. EA's wire
        # form for unlimited is "*" (never "-1" — the reference
        # exports contain no value="-1" at all).
        DEFAULT_LOWER = Ea::Qea::Rules::Cardinality::DEFAULT_MIN
        DEFAULT_UPPER = Ea::Qea::Rules::Cardinality::DEFAULT_MAX

        # EA writes an explicit 1..1 for a Property whose t_attribute
        # bound columns are BOTH blank, rather than falling back to the
        # UML unspecified multiplicity.
        DEFAULT_ATTRIBUTE_BOUNDS = { lower: "1", upper: "1" }.freeze

        module_function

        # The bound pair for a t_attribute row. The 1..1 default is a
        # property of the PAIR — with one column set, the missing side
        # keeps the normal UML fallback, so `2` and a blank upper is
        # 2..* rather than the invalid 2..1.
        #
        # @param lower [String, Integer, nil] t_attribute.lowerbound
        # @param upper [String, Integer, nil] t_attribute.upperbound
        # @return [Hash{Symbol=>String}] `{ lower:, upper: }`
        def attribute_bounds(lower, upper)
          both_blank = lower.to_s.strip.empty? && upper.to_s.strip.empty?
          return DEFAULT_ATTRIBUTE_BOUNDS if both_blank

          { lower: normalize_lower(lower), upper: normalize_upper(upper) }.freeze
        end

        # @param raw [String, nil] e.g. "1..*", "0..1", "1", "*", nil
        # @return [Hash{Symbol=>String}] `{ lower:, upper: }` always
        #   populated; never nil. Empty/nil input returns the UML default.
        def parse(raw)
          parsed = Ea::Qea::Rules::Cardinality.parse(raw)
          { lower: parsed[:min], upper: parsed[:max] }
        end

        # Normalise an upper-bound token: `*` / `unbounded` → `*`
        # (the LiteralUnlimitedNatural wire form EA also uses).
        # @param raw [String, Integer, nil]
        # @return [String]
        def normalize_upper(raw)
          Ea::Qea::Rules::Cardinality.normalize_max(raw)
        end

        # Normalise a lower-bound token: empty/nil → "0" (UML default).
        # Unlimited tokens also → "0" — a lower bound serializes as
        # uml:LiteralInteger, which cannot hold `*` or `-1`.
        # @param raw [String, Integer, nil]
        # @return [String]
        def normalize_lower(raw)
          Ea::Qea::Rules::Cardinality.normalize_min(raw)
        end

      end
    end
  end
end
