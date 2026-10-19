# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits the operation compartment text `<g>`. Each operation
        # renders as TWO `<text>` elements matching EA's encoding:
        #
        #   <text>+ </text>
        #   <text>methodName(params): ReturnType</text>
        #
        # Rendered as a third compartment below the attribute
        # compartment for Klass / Interface classifiers.
        class OperationRenderer
          VISIBILITY_X_OFFSET = 5
          CONTENT_X_OFFSET = 22

          def self.render(operations, bounds:, first_y:, family:, size:, size_unit: "px",
                          logical_height: nil, parameter_detail: nil)
            # EA's op rows pitch 13 (size + 6), same as attribute
            # rows (6D4C665D: ops 541..658 step 13).
            line_h = Ea::Fonts::Metrics.compartment_line_height(
              size, family: family, unit: size_unit, logical_height: logical_height
            )
            text_blocks = []
            has_receptions = operations.any?(&:is_reception)
            if has_receptions
              heading_width = reception_heading_width(family, size, size_unit, logical_height)
              text_blocks << TextRenderer.new(
                content: "receptions",
                x: bounds.x + (bounds.width / 2.0) - heading_width / 2.0,
                y: first_y,
                family: family, size: size, size_unit: size_unit, logical_height: logical_height,
                style: "italic", fill: "#000000"
              ).to_svg
            end
            ops = has_receptions ? operations : operations
            offset = has_receptions ? 1 : 0
            content_x_offset = CONTENT_X_OFFSET + 2 * (size - 7)
            content_x_offset -= 1 if Ea::Fonts::Metrics.compact_compartment_font?(size, family: family, unit: size_unit)
            ops.each_with_index do |op, idx|
              y = first_y + ((idx + offset) * line_h)
              text_blocks << build_text(bounds.x + VISIBILITY_X_OFFSET, y,
                                        visibility_prefix(op), family, size, size_unit, logical_height: logical_height)
              text = operation_text(op, parameter_detail: parameter_detail)
              text_blocks << build_text(bounds.x + content_x_offset, y,
                                        text, family, size, size_unit, logical_height: logical_height)
            end
            %(<g style="#{Style::TEXT_GROUP}">\n#{text_blocks.join("\n")}\n</g>)
          end

          # Builds display lines for a classifier's operations.
          def self.lines_for(classifier, parameter_detail: nil)
            ops = classifier.operations
            return [] unless ops&.any?

            ops.map do |op|
              visibility = visibility_prefix(op).strip
              params = (op.parameters || []).map do |p|
                type = namespace_double_colon(p.type_name)
                parameter_text(p, type, parameter_detail)
              end.join(", ")
              return_type = namespace_double_colon(op.return_type_name)
              "#{visibility} #{op.name}(#{params}): #{return_type}".strip
            end
          end

          def self.visibility_prefix(operation)
            VisibilitySymbol.for(operation.visibility, with_space: true)
          end
          private_class_method :visibility_prefix

          def self.operation_text(operation, parameter_detail: nil)
            prefix = operation.is_reception ? "«signal» " : ""
            text = "#{prefix}#{operation.name}(#{reception_params(operation, parameter_detail)})"
            return text unless operation.return_type_name && !operation.is_reception

            "#{text}: #{operation.return_type_name}"
          end
          public_class_method :operation_text

          def self.namespace_double_colon(type_name)
            return "" if type_name.nil? || type_name.empty?

            type_name.to_s.gsub(/([A-Za-z0-9_]):([A-Za-z])/, '\1::\2')
          end
          private_class_method :namespace_double_colon

          def self.parameter_text(param, type, parameter_detail)
            return "#{type}*" if param.direction == "inout"
            return type if parameter_detail == :type_only

            "#{param.name}: #{type}"
          end
          private_class_method :parameter_text

          def self.reception_params(operation, parameter_detail)
            params = (operation.parameters || []).filter_map { |p|
              next nil if p.type_name.to_s.empty?

              parameter_text(p, p.type_name, parameter_detail)
            }.join(", ")
            params
          end
          private_class_method :reception_params

          def self.reception_heading_width(family, size, size_unit, logical_height)
            TextRenderer.estimate_width(
              "receptions", size,
              family: family, weight: 400, style: "italic",
              logical_height: size_unit == "pt" ? logical_height : nil
            ).round
          end
          private_class_method :reception_heading_width

          def self.build_text(x, y, content, family, size, size_unit, logical_height: nil)
            TextRenderer.new(content: content, x: x, y: y,
                             family: family, size: size, size_unit: size_unit,
                             logical_height: logical_height).to_svg
          end
          private_class_method :build_text
        end
      end
    end
  end
end
