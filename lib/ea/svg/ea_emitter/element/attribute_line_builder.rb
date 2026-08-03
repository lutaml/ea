# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Builds the text representation of a single property line
        # for the attribute compartment. Encapsulates the four EA
        # rendering rules:
        #
        #   1. Visibility marker (+, -, #, ~).
        #   2. Namespace prefix on properties inherited from a
        #      classifier in a different package ("core::mimeType").
        #   3. Primitive type name stripping ("xs::double" → "double").
        #   4. Multiplicity shorthand ("[2..2]" → "[2]") and
        #      `{ordered}` modifier.
        #
        # Stateless: each call returns a fresh line String. Pass a
        # `Lookup` to enable cross-classifier resolution (namespace
        # prefix). Without a lookup, the line is rendered as-is
        # (backwards-compatible).
        class AttributeLineBuilder
          # XSD primitive types whose namespace prefix EA drops in
          # the rendered attribute line. The full set is not yet
          # reverse-engineered — leave empty for now so we never
          # wrongly strip a prefix. TODO-D 47 will populate this
          # once verified per-diagram.
          PRIMITIVE_TYPES = Set.new([]).freeze

          attr_reader :property, :host, :lookup

          # property - the Ea::Model::Property to render
          # host     - the Ea::Model::Classifier whose compartment
          #            we're rendering (determines "inherited" status)
          # lookup   - object responding to `#call(id) -> Classifier`
          #            used to resolve the property's declaring
          #            classifier (defaults to no lookup).
          def initialize(property, host: nil, lookup: nil)
            @property = property
            @host = host
            @lookup = lookup
          end

          def to_s
            parts = ["#{visibility_marker} "]
            parts << namespaced_name
            type_str = formatted_type
            parts << ": #{type_str}" unless type_str.empty?
            mult = multiplicity
            parts << " #{mult}" unless mult.empty?
            parts << " = #{property.default_value}" if property.default_value && !property.default_value.to_s.empty?
            parts.join.rstrip
          end

          private

          def visibility_marker
            case property.visibility
            when "private"   then "-"
            when "protected" then "#"
            when "package"   then "~"
            else "+"
            end
          end

          # Property name, prefixed with the declaring classifier's
          # package name when the property is inherited from a
          # different package than the host classifier.
          def namespaced_name
            prefix = inherited_namespace_prefix
            base = property.name.to_s
            prefix && !prefix.empty? ? "#{prefix}::#{base}" : base
          end

          # Returns the declaring classifier's package name when it
          # differs from the host's package; nil otherwise.
          def inherited_namespace_prefix
            return nil unless host && lookup
            return nil if property.owner_id.nil? || property.owner_id == host.id

            owner = lookup.call(property.owner_id)
            return nil unless owner.is_a?(Ea::Model::Classifier)
            return nil if owner.package_id.nil?
            return nil if owner.package_id == host.package_id

            owner.package_name
          end

          # Format the type name. Primitive types from the PRIMITIVE_TYPES
          # set render bare; everything else renders verbatim from the
          # source. The source already provides the correct colon form
          # (single for XSD, double for UML package qualifiers).
          def formatted_type
            raw = property.type_name.to_s
            return "" if raw.empty?

            simple = raw.split(":").last.to_s.split("::").last.to_s
            PRIMITIVE_TYPES.member?(simple) ? simple : raw
          end

          def multiplicity
            lower = property.multiplicity_lower
            upper = property.multiplicity_upper
            return "" if lower.nil? && upper.nil?
            return "" if lower == 1 && upper == 1

            "[#{lower || 0}..#{bound_text(upper)}]"
          end

          def bound_text(value)
            value == -1 ? "*" : value.to_s
          end
        end
      end
    end
  end
end
