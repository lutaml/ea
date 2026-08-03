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
          CONTENT_X_OFFSET = 20

          def self.render(operations, bounds:, first_y:, family:, size:)
            line_h = size + 4
            text_blocks = []
            has_receptions = operations.any?(&:is_reception)
            if has_receptions
              text_blocks << TextRenderer.new(
                content: "receptions",
                x: bounds.x + (bounds.width / 2.0) - (8 * size * 0.65) / 2,
                y: first_y,
                family: family, size: size,
                style: "italic", fill: "#000000"
              ).to_svg
            end
            ops = has_receptions ? operations : operations
            offset = has_receptions ? 1 : 0
            ops.each_with_index do |op, idx|
              y = first_y + ((idx + offset) * line_h)
              text_blocks << build_text(bounds.x + VISIBILITY_X_OFFSET, y,
                                         visibility_prefix(op), family, size)
              text_blocks << build_text(bounds.x + CONTENT_X_OFFSET, y,
                                         operation_text(op), family, size)
            end
            %(<g style="#{Style::TEXT_GROUP}">\n#{text_blocks.join("\n")}\n</g>)
          end

          # Builds display lines for a classifier's operations.
          def self.lines_for(classifier)
            ops = classifier.operations
            return [] unless ops&.any?

            ops.map do |op|
              visibility = visibility_prefix(op).strip
              params = (op.parameters || []).map { |p| "#{p.name}: #{namespace_double_colon(p.type_name)}" }.join(", ")
              return_type = namespace_double_colon(op.return_type_name)
              "#{visibility} #{op.name}(#{params}): #{return_type}".strip
            end
          end

          def self.visibility_prefix(operation)
            VisibilitySymbol.for(operation.visibility, with_space: true)
          end
          private_class_method :visibility_prefix

          def self.operation_text(operation)
            prefix = operation.is_reception ? "«signal» " : ""
            text = "#{prefix}#{operation.name}(#{reception_params(operation)})"
            return text unless operation.return_type_name && !operation.is_reception

            "#{text}: #{operation.return_type_name}"
          end
          public_class_method :operation_text

          def self.namespace_double_colon(type_name)
            return "" if type_name.nil? || type_name.empty?

            type_name.to_s.gsub(/([A-Za-z0-9_]):([A-Za-z])/, '\1::\2')
          end
          private_class_method :namespace_double_colon

          def self.reception_params(operation)
            params = (operation.parameters || []).filter_map { |p|
              p.type_name.to_s.empty? ? nil : p.type_name.to_s
            }.join(", ")
            params
          end
          private_class_method :reception_params

          def self.build_text(x, y, content, family, size)
            TextRenderer.new(content: content, x: x, y: y,
                              family: family, size: size).to_svg
          end
          private_class_method :build_text
        end
      end
    end
  end
end
