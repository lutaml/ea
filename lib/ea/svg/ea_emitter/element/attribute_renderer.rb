# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits the attribute compartment text `<g>`. Each attribute
        # renders as TWO `<text>` elements (visibility marker +
        # content) matching EA's encoding.
        class AttributeRenderer
          DEFAULT_VISIBILITY_X_OFFSET = 5
          DEFAULT_CONTENT_X_OFFSET = 26
          DEFAULT_FONT_UNIT = "pt"

          def self.render(lines, bounds:, first_y:, family:,
                          size:, size_unit: DEFAULT_FONT_UNIT,
                          fill: "#000000",
                          visibility_x_offset: DEFAULT_VISIBILITY_X_OFFSET,
                          content_x_offset: DEFAULT_CONTENT_X_OFFSET)
            line_h = size + 4
            text_blocks = []
            lines.each_with_index do |line, idx|
              y = first_y + (idx * line_h)
              visibility, rest = split_visibility(line)
              if visibility
                text_blocks << build_text(bounds.x + visibility_x_offset, y, visibility, family, size, size_unit, fill)
                text_blocks << build_text(bounds.x + content_x_offset, y, rest, family, size, size_unit, fill)
              else
                text_blocks << build_text(bounds.x + visibility_x_offset, y, line.strip, family, size, size_unit, fill)
              end
            end
            group_style = "stroke-width:1;stroke-linecap:round;stroke-linejoin:bevel; fill:#{fill};fill-opacity:1.00; stroke:#000000; stroke-opacity:0.00"
            %(<g style="#{group_style}">\n#{text_blocks.join("\n")}\n</g>)
          end

          # Builds attribute display lines from classifier properties,
          # hiding properties that are navigable association ends
          # (those are rendered as connector lines).
          #
          # When a property carries a stereotype (e.g. «voidable»),
          # EA renders the stereotype label as a separate line above
          # the property's own line. We insert those labels here so
          # the renderer's per-line spacing naturally places them.
          #
          # Pass a `lookup` (any callable returning a Classifier for
          # an id) to enable inherited-property namespace prefixing.
          def self.lines_for(classifier, lookup: nil)
            props = displayable_properties(classifier)
            return [] unless props

            props.flat_map do |prop|
              lines = []
              stereotype = property_stereotype(prop)
              lines << "«#{stereotype}»" if stereotype
              lines << AttributeLineBuilder.new(prop, host: classifier,
                                                  lookup: lookup).to_s
            end
          end

          # Internal helpers

          def self.split_visibility(line)
            stripped = line.strip
            return [nil, stripped] unless stripped.match?(/^[-+~#]\s/)

            visibility = "#{stripped[0]} "
            rest = stripped[2..].to_s.strip
            [visibility, rest]
          end
          private_class_method :split_visibility

          def self.build_text(x, y, content, family, size, size_unit = DEFAULT_FONT_UNIT, fill = "#000000")
            TextRenderer.new(content: content, x: x, y: y,
                              family: family, size: size, size_unit: size_unit, fill: fill).to_svg
          end
          private_class_method :build_text

          def self.displayable_properties(classifier)
            return nil unless classifier.properties

            classifier.properties.reject(&:association_id)
          end
          private_class_method :displayable_properties

          # Returns the first stereotype ref for a property, or nil.
          # Used to emit «voidable» (and similar) labels above the
          # property's own line.
          def self.property_stereotype(property)
            refs = property.stereotype_refs
            return nil unless refs&.any?

            refs.first.to_s
          end
          private_class_method :property_stereotype

          # EA renders namespace separators as "::" (UML standard)
          # even when the source XMI stores them as ":" (XML style).
          def self.namespace_double_colon(type_name)
            return nil if type_name.nil? || type_name.empty?

            type_name.to_s.gsub(/([A-Za-z0-9_]):([A-Za-z])/, '\1::\2')
          end
          private_class_method :namespace_double_colon

          def self.multiplicity_text(property)
            lower = property.multiplicity_lower
            upper = property.multiplicity_upper
            return "" if lower.nil? && upper.nil?
            return "" if lower == 1 && upper == 1
            return "[#{upper == -1 ? "*" : upper}]" if lower == upper

            "[#{lower || 0}..#{upper == -1 ? "*" : upper}]"
          end
          private_class_method :multiplicity_text
        end
      end
    end
  end
end
