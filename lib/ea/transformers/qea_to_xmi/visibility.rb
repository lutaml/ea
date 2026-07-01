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
        # @return [String, nil] UML visibility token, or nil if EA's
        #   scope field is blank / unrecognised.
        def from_scope(raw)
          return nil if raw.nil? || raw.to_s.strip.empty?

          key = raw.to_i
          SCOPE_MAP[key]
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
        # @return [String, nil] "true" or "false", or nil if unspecified.
        def boolean_from_flag(raw)
          return nil if raw.nil? || raw.to_s.strip.empty?

          raw.to_s == "1" ? "true" : "false"
        end
      end
    end
  end
end
