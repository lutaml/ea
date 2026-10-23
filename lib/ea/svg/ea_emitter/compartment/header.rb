# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Header compartment: stereotype label + class name. Skips
        # rendering when the classifier produces no header lines.
        module Header
          # The pen the first group of this compartment leaves behind.
          def self.pen(_context)
            Pen::ROUND_BEVEL
          end

          module_function

          def render(context)
            return nil if context.header_lines.empty?
            return nil unless context.geometry.header_first_y

            Element::HeaderRenderer.render(
              context.header_lines,
              bounds: context.bounds,
              first_y: context.geometry.header_first_y,
              family: context.family, size: context.size,
              size_unit: context.size_unit, logical_height: context.logical_height,
              fill: context.theme.text_color,
              weight_normal: context.theme.text_weight_normal,
              weight_bold: context.theme.text_weight_bold,
              stroke_in_text: context.theme.stroke_in_text_color,
              width_factor: context.theme.text_width_factor,
              line_offset: context.theme.compartments.header_line_offset,
              default_signal_header: default_signal_header?(context)
            )
          end

          # No element font size of its own: QEA marks it inherited, XMI
          # records the missing size without the flag.
          def default_signal_header?(context)
            context.classifier.is_a?(Ea::Model::Signal) &&
              context.classifier.stereotype_refs.empty? &&
              context.element.font_size.nil? &&
              context.element.font_family.nil? &&
              !context.element.font_bold && !context.element.font_italic
          end
        end
      end
    end
  end
end
