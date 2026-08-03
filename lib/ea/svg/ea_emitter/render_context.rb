# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Per-element render context. Holds the immutable inputs each
      # compartment renderer needs (bounds, classifier, fill/stroke,
      # font, geometry, line data). Built once per element; passed
      # to every compartment in the pipeline so they don't reach
      # back into the parent Elements orchestrator.
      #
      # Value object: equality by structural attributes. Each
      # instance is frozen after construction.
      class RenderContext < Struct.new(
        :element, :bounds, :model_element, :classifier,
        :fill, :stroke, :stroke_width, :text_fill,
        :family, :size, :size_unit,
        :header_lines, :attr_lines, :op_lines,
        :enum_literals, :tagged_values, :constraints,
        :package_content_lines,
        :geometry, :theme, :canvas, :diagram, :model_index,
        :off_canvas_parent_name,
        keyword_init: true
      )
        def note_body
          return nil unless model_element.is_a?(Ea::Model::Note)

          body = model_element.body
          body.nil? || body.empty? ? nil : body
        end

        # Resolve a model element by id via the threaded model index.
        # Returns nil when no index is wired in or the id is absent.
        def model_index_for(id)
          return nil unless model_index && id

          model_index[id]
        end

        # Compartments below the header that produce a divider when
        # any of them has content. Returns true when at least one
        # is non-empty.
        def content_below_header?
          !attr_lines.empty? || !op_lines.empty? ||
            enum_literals.any? || tagged_values.any? ||
            (constraints&.any?) ||
            (!package_content_lines.nil? && !package_content_lines.empty?)
        end
      end
    end
  end
end
