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
          DEFAULT_CONTENT_X_OFFSET = 22
          DEFAULT_FONT_UNIT = "pt"
          # EA seats compartment stereotype headers («Property») 12px
          # from the box edge and spaces rows 13px at 7pt.
          STEREOTYPE_HEADER_X_OFFSET = 12
          ROW_LINE_OFFSET = 6

          def self.render(lines, bounds:, first_y:, family:,
                          size:, size_unit: DEFAULT_FONT_UNIT,
                          fill: "#000000",
                          visibility_x_offset: DEFAULT_VISIBILITY_X_OFFSET,
                          content_x_offset: DEFAULT_CONTENT_X_OFFSET)
            line_h = size + ROW_LINE_OFFSET
            text_blocks = []
            lines.each_with_index do |line, idx|
              y = first_y + (idx * line_h)
              visibility, rest = split_visibility(line)
              if visibility
                text_blocks << build_text(bounds.x + visibility_x_offset, y, visibility, family, size, size_unit, fill)
                text_blocks << build_text(bounds.x + content_x_offset, y, rest, family, size, size_unit, fill)
              elsif line.strip.start_with?("«")
                text_blocks << build_text(bounds.x + STEREOTYPE_HEADER_X_OFFSET, y, line.strip, family, size, size_unit, fill)
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
          def self.lines_for(classifier, lookup: nil,
                            exclude_association_ids: nil)
            props = displayable_properties(classifier, exclude_association_ids)
            return [] unless props

            stereotypes = props.map { |p| property_stereotype(p) }.compact.uniq
            if stereotypes.size == 1 && props.all? { |p| property_stereotype(p) }
              # EA renders ONE compartment stereotype header for a
              # uniformly-stereotyped attribute set (e.g. «Property»
              # above GML property rows) and lists rows
              # alphabetically - verified against EA-published SVGs.
              header = "«#{canonical_stereotype(stereotypes.first)}»"
              [header] + props.sort_by { |p| p.name.to_s }.map do |prop|
                AttributeLineBuilder.new(prop, host: classifier,
                                         lookup: lookup).to_s
              end
            else
              # EA lists attribute rows alphabetically (case-
              # insensitive) — corpus-verified: 991 boxes strictly
              # alphabetical vs 24 strictly stored-Pos order.
              props.sort_by { |p| [p.name.to_s.downcase, p.name.to_s] }
                   .flat_map do |prop|
                lines = []
                stereotype = property_stereotype(prop)
                lines << "«#{stereotype}»" if stereotype
                lines << AttributeLineBuilder.new(prop, host: classifier,
                                                  lookup: lookup).to_s
              end
            end
          end

          STEREOTYPE_DISPLAY = {
            "property" => "Property",
            "featuretype" => "FeatureType",
            "objecttype" => "ObjectType",
            "codelist" => "CodeList"
          }.freeze

          def self.canonical_stereotype(ref)
            STEREOTYPE_DISPLAY.fetch(ref.to_s.downcase, ref.to_s)
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

          # Association-end properties render in the box only when
          # their association is NOT drawn on the diagram (drawn ones
          # render as connector role labels). exclude_association_ids
          # carries the diagram's drawn association ids; nil preserves
          # the legacy hide-all behavior.
          def self.displayable_properties(classifier, exclude_association_ids)
            return nil unless classifier.properties

            classifier.properties.reject do |prop|
              prop.association_id &&
                (exclude_association_ids.nil? ||
                 exclude_association_ids.include?(prop.association_id))
            end
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
