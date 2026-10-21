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
        :family, :size, :size_unit, :logical_height,
        :header_lines, :attr_lines, :op_lines,
        :enum_literals, :tagged_values, :constraints, :marker_lines,
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
            (!package_content_lines.nil? && !package_content_lines.empty?) ||
            hidden_features_present?
        end

        # EA draws the header divider whenever the element HAS a
        # feature compartment — even one whose rows are all hidden
        # by visibility flags (10E3E08A: CodeList with 3 attributes
        # toggled off still renders the divider over an empty body;
        # only feature-less elements omit it). Association-end
        # properties are not EA attributes (QEA keeps them as connector
        # roles; the XMI reads them as ownedAttribute), so a class whose
        # only properties are association ends has no feature compartment
        # and no divider (A59065AF urf::Administration).
        #
        # A diagram that suppresses a whole feature kind (Style
        # HideAtts=1 / HideOps=1) has no such compartment to draw, so
        # that kind never earns a divider: 4881CEEE (HideAtts=1 and
        # HideOps=1) draws none over classes that own attributes,
        # 8FD488EF likewise. Per-attribute visibility toggles are a
        # different mechanism and keep the divider (10E3E08A).
        def hidden_features_present?
          return false unless classifier.respond_to?(:properties)

          config = diagram&.display_config
          shows_attributes = config.nil? || config.show_attributes?
          shows_operations = config.nil? || config.show_operations?

          (shows_attributes && classifier.properties.any? { |property| !property.association_id }) ||
            (shows_operations && classifier.operations.any?)
        end
      end
    end
  end
end
