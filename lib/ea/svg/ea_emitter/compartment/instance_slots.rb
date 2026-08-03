# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Instance slot compartment. Renders each slot on an
        # InstanceSpecification as "name op value", then appends
        # "(from PackageName)" in italics below the slots when the
        # instance has a classifier. Skipped entirely when the model
        # element is not an InstanceSpecification or has neither
        # slots nor a classifier.
        module InstanceSlots
          ROW_OFFSET = 13
          SUBTITLE_EXTRA_OFFSET = 10

          module_function

          def render(context)
            return nil unless instance?(context)

            instance = context.model_element
            slots = instance.slots || []
            subtitle = from_package_subtitle(instance)
            return nil if slots.empty? && subtitle.nil?

            first_y = context.geometry.attr_first_y
            bounds = context.bounds
            fill = context.theme.attribute_text_color
            blocks = []
            slots.each_with_index do |slot, idx|
              y = first_y + (idx * ROW_OFFSET)
              blocks << line_text(slot, bounds, y, context, fill)
            end
            if subtitle
              y = first_y + (slots.size * ROW_OFFSET) + SUBTITLE_EXTRA_OFFSET
              blocks << subtitle_text(subtitle, bounds, y, context, fill)
            end
            wrap(blocks.join("\n"), fill)
          end

          def instance?(context)
            context.model_element.is_a?(Ea::Model::InstanceSpecification)
          end
          module_function :instance?

          def from_package_subtitle(instance)
            pkg = instance.package_name
            return nil if pkg.nil? || pkg.empty?

            classifier = instance.classifier_name
            return nil if classifier.nil? || classifier.empty?

            "(from #{pkg})"
          end
          module_function :from_package_subtitle

          def line_text(slot, bounds, y_pos, context, fill)
            content = "#{slot.name} #{slot.op} #{slot.value}"
            TextRenderer.new(
              content: content,
              x: bounds.x + (context.theme.attribute_spec.content_x_offset || 26),
              y: y_pos,
              family: context.family, size: context.size,
              size_unit: context.size_unit, fill: fill
            ).to_svg
          end
          module_function :line_text

          def subtitle_text(text, bounds, y_pos, context, fill)
            estimated_width = text.length * context.size * 0.5
            x_pos = bounds.x + (bounds.width - estimated_width) / 2.0
            TextRenderer.new(
              content: text,
              x: x_pos,
              y: y_pos,
              family: context.family, size: context.size,
              size_unit: context.size_unit, fill: fill,
              style: "italic"
            ).to_svg
          end
          module_function :subtitle_text

          def wrap(body, fill)
            group_style = "stroke-width:1;stroke-linecap:round;" \
                          "stroke-linejoin:bevel; fill:#{fill};" \
                          "fill-opacity:1.00; stroke:#000000;" \
                          " stroke-opacity:0.00"
            %(<g style="#{group_style}">\n#{body}\n</g>)
          end
          module_function :wrap
        end
      end
    end
  end
end
