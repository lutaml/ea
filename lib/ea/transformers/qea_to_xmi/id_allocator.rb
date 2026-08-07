# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Allocates synthetic xmi:id values for elements that don't have a
      # natural GUID-based one — literal `<lowerValue>`/`<upperValue>`
      # bounds, instance slots and their values, return parameters.
      #
      # EA's scheme, derived from examples/exports/*/model.xml:
      #
      #   EAID_<PREFIX><NNNNNN><SEP><TAIL27>
      #
      # - `<PREFIX>` is a Sparx-reserved literal prefix (LI, SL, OE, RT).
      # - `<NNNNNN>` is a 6-digit zero-padded counter. LI counts GLOBALLY
      #   from 1 in allocation order (lower before upper, destination end
      #   before source end, document walk order across owners). SL, OE
      #   and RT count from 0 PER OWNING ELEMENT (slots/values per
      #   InstanceSpecification, return parameters per operation).
      # - `<TAIL27>` is the owner ID's last 27 characters (the EA GUID
      #   minus its first segment).
      # - `<SEP>` is as many underscores as keep the synthesized ID the
      #   same total width as the owner ID (one for 41-char EAID_ owners,
      #   two for 42-char src/dst association-end owners).
      #
      # The allocator memoizes by [owner_id, prefix, seed]: the same
      # triple always returns the same ID without advancing any counter.
      #
      # @api private — internal to the QeaToXmi transformer; its
      # signature follows the transformer's needs, not semver.
      class IdAllocator
        # Well-known prefixes Sparx uses for synthesized IDs.
        LITERAL_INTEGER   = "LI"
        OPAQUE_EXPRESSION = "OE"
        SLOT              = "SL"
        RETURN_PARAMETER  = "RT"

        # Prefixes whose counter runs across the whole document, starting
        # at 1. All other prefixes restart at 0 per owner.
        GLOBAL_PREFIXES = [LITERAL_INTEGER].freeze

        TAIL_LENGTH = 27
        # "EAID_" plus the 8-character prefix+counter token.
        HEAD_LENGTH = 13

        def initialize
          @global_counters = Hash.new(0)
          @owner_counters = Hash.new(0)
          @assigned = {}
        end

        # @param prefix [String] LITERAL_INTEGER, SLOT, OPAQUE_EXPRESSION
        #   or RETURN_PARAMETER
        # @param owner_id [String] the owning element's full xmi:id — its
        #   last 27 characters become the tail and its width sets the
        #   separator
        # @param seed [String] stable memoization key within the owner
        # @return [String] e.g. "EAID_LI000001__EEB1_4de7_98F5_670D6EE4A52B"
        def allocate(prefix:, owner_id:, seed:)
          key = [owner_id, prefix, seed]
          return @assigned[key] if @assigned.key?(key)

          @assigned[key] = compose_id(prefix, next_counter(prefix, owner_id), owner_id)
        end

        private

        def next_counter(prefix, owner_id)
          if GLOBAL_PREFIXES.include?(prefix)
            @global_counters[prefix] += 1
          else
            n = @owner_counters[[prefix, owner_id]]
            @owner_counters[[prefix, owner_id]] = n + 1
            n
          end
        end

        def compose_id(prefix, counter, owner_id)
          # QEA guid columns are nullable — an owner with no id (or one
          # too short to carry a 27-char tail) gets a tailless,
          # counter-only identifier.
          return format("EAID_%<prefix>s%<n>06d", prefix: prefix, n: counter) if
            owner_id.to_s.length < TAIL_LENGTH + HEAD_LENGTH

          tail = owner_id[-TAIL_LENGTH..]
          separator = "_" * (owner_id.length - TAIL_LENGTH - HEAD_LENGTH)
          format("EAID_%<prefix>s%<n>06d%<sep>s%<tail>s",
                 prefix: prefix, n: counter, sep: separator, tail: tail)
        end
      end
    end
  end
end
