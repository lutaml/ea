# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Pure-function mapper from EA's integer scope/containment codes
      # to UML visibility / aggregation wire strings.
      #
      # EA stores visibility as an integer in `t_attribute.scope`,
      # `t_operation.scope`, `t_object.scope`. The encoding:
      #
      #   0 → Public
      #   1 → Private
      #   2 → Protected
      #   3 → Package
      #
      # EA stores aggregation kind in `t_connector.sourcecontainment`
      # and `t_connector.destcontainment`. The encoding:
      #
      #   0 → None (omitted)
      #   1 → Shared (UML aggregation="shared")
      #   2 → Composite (UML aggregation="composite")
      #
      # Wire-side values are lower-case per the UML XMI schema.
      module Visibility
        SCOPE_MAP = {
          0 => "public",
          1 => "private",
          2 => "protected",
          3 => "package",
        }.freeze

        AGGREGATION_MAP = {
          0 => nil,
          1 => "shared",
          2 => "composite",
        }.freeze

        module_function

        # @param raw [String, Integer, nil]
        # @return [String, nil] UML visibility token. Returns nil for
        #   blank/unrecognised values AND for the UML default ("public")
        #   so the xmi gem omits the attribute — matching EA's output,
        #   which doesn't emit visibility="public".
        def from_scope(raw)
          return nil if raw.nil? || raw.to_s.strip.empty?

          value = SCOPE_MAP[raw.to_i]
          return nil if value == "public"

          value
        end

        # @param raw [String, Integer, nil]
        # @return [String, nil] UML aggregation token, or nil if EA's
        #   containment field indicates no aggregation.
        def aggregation_from_containment(raw)
          return nil if raw.nil? || raw.to_s.strip.empty?

          key = raw.to_i
          AGGREGATION_MAP[key]
        end

        # @param raw [String, Integer, nil] EA's abstract flag ("1"/"0")
        # @return [Boolean, nil] true when EA marks the element abstract,
        #   nil when blank OR "0" (false). Returning nil for false makes
        #   the xmi gem omit isAbstract="false" — matching EA's output,
        #   which doesn't emit the default.
        def boolean_from_flag(raw)
          return nil if raw.nil? || raw.to_s.strip.empty?
          return nil if raw.to_s == "0"

          raw.to_s == "1"
        end
      end
    end
  end
end
