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
          # EA seats each group-header row («...» following a
          # non-stereotype row) 4px below the uniform pitch (XSD
          # schema diagrams: attr row 68 -> «XSDelement» 85 -> row 98;
          # single-header boxes like «Property» sit at the first row
          # and keep the plain pitch).
          GROUP_HEADER_LEAD = 4

          def self.group_lead_offsets(lines)
            extra = 0
            lines.each_with_index.map do |line, idx|
              stereo = line.to_s.strip.start_with?("«")
              prev_stereo = idx.positive? ? lines[idx - 1].to_s.strip.start_with?("«") : true
              extra += GROUP_HEADER_LEAD if stereo && idx.positive? && !prev_stereo
              extra
            end
          end

          def self.group_lead_total(lines)
            group_lead_offsets(lines).last.to_i
          end

          # EA seats compartment stereotype headers («Property») 12px
          # from the box edge and spaces rows 13px at 7pt.
          STEREOTYPE_HEADER_X_OFFSET = 12
          ROW_LINE_OFFSET = 6


          # EA scales the row text inset with point size:
          # 7pt rows sit at box.x+22, 9pt at box.x+26 (the '+ '
          # visibility run stays at box.x+5 for both).
          def self.content_x_offset(size)
            DEFAULT_CONTENT_X_OFFSET + 2 * (size - 7)
          end

          def self.render(lines, bounds:, first_y:, family:,
                          size:, size_unit: DEFAULT_FONT_UNIT, logical_height: nil,
                          fill: "#000000",
                          visibility_x_offset: DEFAULT_VISIBILITY_X_OFFSET,
                          content_x_offset: nil)

            line_h = Ea::Fonts::Metrics.compartment_line_height(
              size, family: family, unit: size_unit, offset: ROW_LINE_OFFSET, logical_height: logical_height
            )
            offsets = group_lead_offsets(lines)
            text_blocks = []
            lines.each_with_index do |line, idx|
              y = first_y + (idx * line_h) + offsets[idx]
              visibility, rest = split_visibility(line)
              if visibility
                unless visibility.strip.empty?
                  text_blocks << build_text(
                    bounds.x + visibility_x_offset, y, visibility, family, size, size_unit, fill,
                    logical_height: logical_height
                  )
                end
                offset = (content_x_offset || DEFAULT_CONTENT_X_OFFSET) +
                         2 * (size - 7)
                offset -= 1 if Ea::Fonts::Metrics.compact_compartment_font?(size, family: family, unit: size_unit)
                text_blocks << build_text(
                  bounds.x + offset, y, rest, family, size, size_unit, fill, logical_height: logical_height
                )
              elsif line.strip.start_with?("«")
                text_blocks << build_text(
                  bounds.x + STEREOTYPE_HEADER_X_OFFSET, y, line.strip, family, size, size_unit, fill,
                  logical_height: logical_height
                )
              else
                text_blocks << build_text(
                  bounds.x + visibility_x_offset, y, line.strip, family, size, size_unit, fill,
                  logical_height: logical_height
                )
              end
            end
            group_style = "stroke-width:1;stroke-linecap:round;stroke-linejoin:bevel; fill:#{fill};fill-opacity:1.00; stroke:#000000; stroke-opacity:0.00"
            %(<g style="#{group_style}">\n#{text_blocks.join("\n")}\n</g>)
          end

          # Builds attribute display lines from classifier properties,
          # hiding association-end properties even when their connectors
          # are not drawn on the diagram.
          #
          # When a property carries a stereotype (e.g. «voidable»),
          # EA renders the stereotype label as a separate line above
          # the property's own line. We insert those labels here so
          # the renderer's per-line spacing naturally places them.
          #
          # Pass a `lookup` (any callable returning a Classifier for
          # an id) to enable inherited-property namespace prefixing.
          def self.lines_for(classifier, lookup: nil,
                             exclude_association_ids: nil, stored_order: false)
            props = displayable_properties(classifier, exclude_association_ids)
            return [] unless props

            stereotypes = props.map { |p| property_stereotype(p) }.compact.uniq
            if stereotypes.size == 1 && props.all? { |p| property_stereotype(p) }
              # EA renders ONE compartment stereotype header for a
              # uniformly-stereotyped attribute set (e.g. «Property»
              # above GML property rows).
              header = "«#{canonical_stereotype(stereotypes.first)}»"
              [header] + ordered_properties(props, stored_order, case_sensitive: true).map do |prop|
                AttributeLineBuilder.new(prop, host: classifier,
                                         lookup: lookup).to_s
              end
            else
              # EMPIRICAL FIT (test B58D1A53, the only corpus class mixing
              # stereotyped and plain attributes): EA draws the plain rows
              # first, then the stereotyped ones in stored order.
              plain, stereotyped = ordered_properties(props, stored_order)
                                   .partition { |prop| property_stereotype(prop).nil? }
              (plain + stereotyped).flat_map do |prop|
                lines = []
                stereotype = property_stereotype(prop)
                lines << "«#{stereotype}»" if stereotype
                lines << AttributeLineBuilder.new(prop, host: classifier,
                                                  lookup: lookup).to_s
              end
            end
          end

          # QEA properties arrive in stored Pos order. Association ends retain
          # their alphabetical fallback rather than using connector Pos values.
          def self.ordered_properties(props, stored_order, case_sensitive: false)
            alphabetical = lambda do |prop|
              name = prop.name.to_s
              case_sensitive ? [name] : [name.downcase, name]
            end
            return props.sort_by(&alphabetical) unless stored_order

            own, ends = props.partition { |prop| !prop.association_id }
            own + ends.sort_by(&alphabetical)
          end
          private_class_method :ordered_properties

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

          def self.build_text(x, y, content, family, size, size_unit = DEFAULT_FONT_UNIT,
                              fill = "#000000", logical_height: nil)
            TextRenderer.new(content: content, x: x, y: y,
                             family: family, size: size, size_unit: size_unit,
                             logical_height: logical_height, fill: fill).to_svg
          end
          private_class_method :build_text

          # Association ends remain in the model for connector role labels,
          # but never become class-compartment attribute rows. The public
          # exclude_association_ids keyword remains accepted for callers.
          def self.displayable_properties(classifier, _exclude_association_ids)
            classifier.properties&.reject(&:association_id)
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
