# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Allocates synthetic xmi:id values for elements that don't have a
      # natural GUID-based one — e.g. literal `<lowerValue>` nodes, or
      # `<ownedComment>` bodies synthesized from EA's Note objects.
      #
      # Sparx's EAID format reserves prefixes like `LI` (LiteralInt),
      # `SL` (Slot), `NL` (NameLabel), `DB` (DiagramBounds), `OE` (OpaqueExpr)
      # for these synthesized identifiers.
      class IdAllocator
        # Well-known prefixes Sparx uses for synthesized IDs.
        LITERAL_INTEGER   = "LI"
        LITERAL_UNLIMITED = "LI" # Sparx reuses the LI prefix for both
        OPAQUE_EXPRESSION = "OE"
        SLOT              = "SL"

        def initialize
          @counter = 0
          @assigned = {}
        end

        # @param prefix [String] e.g. "LI", "OE"
        # @param seed [String, nil] stable seed for memoization (object_id of
        #   the source record). Same seed returns same allocated id.
        # @return [String] e.g. "EAID_LI000001_..."
        def allocate(prefix:, seed: nil)
          return @assigned[seed] if seed && @assigned.key?(seed)

          @counter += 1
          id = format("%<prefix>s%<n>06d", prefix: prefix, n: @counter)
          @assigned[seed] = id if seed
          id
        end

        # @param value [String, Integer, nil]
        # @return [String] a LiteralInteger / LiteralUnlimitedNatural-style id
        def for_multiplicity(value, seed:)
          return @assigned[seed] if @assigned.key?(seed)

          @counter += 1
          id = format("%<prefix>s%<n>06d", prefix: LITERAL_INTEGER, n: @counter)
          @assigned[seed] = id
          id
        end
      end
    end
  end
end
