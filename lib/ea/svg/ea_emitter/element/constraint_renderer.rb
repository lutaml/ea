# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits the constraints compartment text `<g>`. EA renders
        # each constraint as a bare "{name}" line — no caption —
        # RIGHT-ALIGNED to the element box's right edge at the 13px
        # compartment pitch, seated between the header divider and
        # the attribute rows. Corpus-verified (TK_PositionType /
        # TK_Position: "{root}" x + textLength lands exactly on the
        # box right edge).
        class ConstraintRenderer
          # right_inset: EA seats {root}/{leaf} marker text 6px inside
          # the box's right edge (E0C65C12/47581C14: our flush
          # right-aligned x is uniformly 6px right of EA's).
          def self.render(constraints, bounds:, first_y:, family:, size:,
                          fill: "#000000", right_inset: 0)
            line_h = size + 6
            text_blocks = constraints.each_with_index.map do |constraint, idx|
              content = "{#{constraint.name}}"
              x = bounds.x + bounds.width -
                  TextRenderer.estimate_width(content, size, nil,
                                              family: family).round -
                  right_inset
              build_text(x, first_y + idx * line_h, content, family, size, fill)
            end
            %(<g style="#{Style::TEXT_GROUP}">\n#{text_blocks.join("\n")}\n</g>)
          end

          def self.render_compartment(context)
            rows = context.constraints.each_with_index.map do |constraint, idx|
              compartment_row(constraint, context, idx)
            end
            %(<g style="#{Style::TEXT_GROUP}">\n#{([compartment_caption(context)] + rows).join("\n")}\n</g>)
          end

          def self.compartment_row(constraint, context, index)
            build_text(context.bounds.x + 5,
                       context.geometry.constraints_first_y + (index + 1) * (context.size + 5),
                       "{#{constraint.name}}", context.family, context.size, context.text_fill)
          end
          private_class_method :compartment_row

          def self.compartment_caption(context)
            TextRenderer.new(content: "constraints", x: caption_x(context),
                             y: context.geometry.constraints_first_y, family: context.family,
                             size: context.size, fill: context.text_fill, style: "italic").to_svg
          end
          private_class_method :compartment_caption

          def self.caption_x(context)
            width = TextRenderer.estimate_width("constraints", context.size, nil,
                                                family: context.family, style: "italic").round
            context.bounds.x + ((context.bounds.width - width) / 2).floor
          end
          private_class_method :caption_x

          def self.build_text(x, y, content, family, size, fill)
            TextRenderer.new(content: content, x: x, y: y,
                              family: family, size: size, fill: fill).to_svg
          end
          private_class_method :build_text
        end
      end
    end
  end
end
