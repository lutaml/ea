# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Pure-function mapper from EA's scope/aggregation codes to UML
      # visibility / aggregation wire strings.
      #
      # QEA databases store scope as text in `t_attribute.Scope`,
      # `t_operation.Scope`, `t_object.Scope`: "Public", "Private",
      # "Protected", "Package". The integer codes (0-3, same order) are
      # kept as a fallback for EAP-era databases.
      #
      # Aggregation kind comes from `t_connector.sourceisaggregate` /
      # `destisaggregate` (via Transformer#containment_for). The encoding:
      #
      #   0 → None (omitted)
      #   1 → Shared (UML aggregation="shared")
      #   2 → Composite (UML aggregation="composite")
      #
      # Wire-side values are lower-case per the UML XMI schema.
      module Visibility
        TEXT_SCOPES = {
          "public" => "public",
          "private" => "private",
          "protected" => "protected",
          "package" => "package",
        }.freeze

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
          text = raw.to_s.strip
          return nil if text.empty?

          value = TEXT_SCOPES[text.downcase] || SCOPE_MAP[text.to_i]
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
