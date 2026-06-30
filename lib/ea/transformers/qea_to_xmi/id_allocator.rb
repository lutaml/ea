# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Allocates synthetic xmi:id values for elements that don't have a
      # natural GUID-based one — e.g. literal `<lowerValue>` nodes, or
      # `<ownedComment>` bodies synthesized from EA's Note objects.
      #
      # Sparx's EAID format reserves prefixes like `LI` (LiteralInt),
      # `SL` (Slot), `NL` (NameLabel), `DB` (DiagramBounds), `OE` (OpaqueExpr),
      # `RT` (Return parameter) for these synthesized identifiers.
      #
      # Output shape: `EAID_<PREFIX><NNNNNN><GUID_TAIL>` where:
      #
      # - `EAID_` matches the prefix used by all other Sparx XMI element IDs.
      # - `<PREFIX>` is a Sparx-reserved literal prefix (LI, SL, OE, ...).
      # - `<NNNNNN>` is a 6-digit zero-padded counter, scoped to the
      #   IdAllocator instance (one per `Transformer#serialize` call).
      # - `<GUID_TAIL>` is the parent element's EA GUID normalised to
      #   Sparx's wire form. The leading underscore from the opening
      #   brace of `{GUID-...}` is preserved so the output matches
      #   real Sparx XMI byte-for-byte (e.g. `EAID_LI000001__EEB1_...`).
      #   When `parent_guid` is nil, no tail is emitted.
      #
      # The allocator is memoised by `seed`: same seed returns the same
      # allocated ID. Different seeds get different counters.
      class IdAllocator
        # Well-known prefixes Sparx uses for synthesized IDs.
        LITERAL_INTEGER   = "LI"
        OPAQUE_EXPRESSION = "OE"
        SLOT              = "SL"
        NAME_LABEL        = "NL"
        DIAGRAM_BOUNDS    = "DB"
        RETURN_PARAMETER  = "RT"

        # Leading-underscore-preserving normalisation: `{AB-CD}` → `_AB_CD`.
        # Matches the wire form Sparx emits for parent-guid-suffixed IDs.
        GUID_BRACE_OR_DASH = /[-{}]/

        def initialize
          @counter = 0
          @assigned = {}
        end

        # @param prefix [String] one of LITERAL_INTEGER, OPAQUE_EXPRESSION, ...
        # @param seed [String, nil] stable seed for memoization (e.g. the
        #   source record's object_id). Same seed returns same allocated id.
        # @param parent_guid [String, nil] the owning element's EA GUID
        #   (e.g. `{EEB1-...}`). When provided, the synthesised ID carries
        #   the parent GUID tail so it is traceable and round-trip-safe.
        # @return [String] e.g. "EAID_LI000001__EEB1_4de7_98F5_670D6EE4A52B"
        def allocate(prefix:, seed: nil, parent_guid: nil)
          return @assigned[seed] if seed && @assigned.key?(seed)

          @counter += 1
          id = compose_id(prefix: prefix, n: @counter, parent_guid: parent_guid)
          @assigned[seed] = id if seed
          id
        end

        private

        def compose_id(prefix:, n:, parent_guid:)
          tail = guid_tail(parent_guid)
          if tail
            # The format is `EAID_LI<NN>_<guid_tail>` where guid_tail
            # preserves its leading underscore. Together with the
            # separator `_` that yields the double-underscore form
            # Sparx emits (`EAID_LI000001__EEB1_...`).
            format("EAID_%<prefix>s%<n>06d_%<tail>s", prefix: prefix, n: n, tail: tail)
          else
            format("EAID_%<prefix>s%<n>06d", prefix: prefix, n: n)
          end
        end

        # Sparx preserves the leading underscore that comes from the
        # opening brace of the EA GUID. Strip the closing-brace trailing
        # underscore only.
        #
        # `{EEB1-4de7-98F5-670D6EE4A52B}` → `_EEB1_4de7_98F5_670D6EE4A52B`
        def guid_tail(parent_guid)
          return nil if parent_guid.nil? || parent_guid.empty?

          parent_guid
            .gsub(GUID_BRACE_OR_DASH, "_")
            .sub(/_\z/, "")
        end
      end
    end
  end
end
