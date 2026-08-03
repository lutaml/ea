# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Per-element compartment renderers. Each class handles one
      # visual layer of an element box: shape rect, header text,
      # divider path, attribute text. Filter predicate also lives
      # here.
      module Element
        autoload :Filter, "ea/svg/ea_emitter/element/filter"
        autoload :BColDecoder, "ea/svg/ea_emitter/element/bcol_decoder"
        autoload :ShapeRenderer, "ea/svg/ea_emitter/element/shape_renderer"
        autoload :PackageShapeRenderer, "ea/svg/ea_emitter/element/package_shape_renderer"
        autoload :NoteShapeRenderer, "ea/svg/ea_emitter/element/note_shape_renderer"
        autoload :HeaderRenderer, "ea/svg/ea_emitter/element/header_renderer"
        autoload :HeaderLines, "ea/svg/ea_emitter/element/header_lines"
        autoload :HeaderLinePipeline, "ea/svg/ea_emitter/element/header_line_pipeline"
        autoload :HeaderLineProvider, "ea/svg/ea_emitter/element/header_line_provider"
        autoload :TextEscape, "ea/svg/ea_emitter/element/text_escape"
        autoload :DividerRenderer, "ea/svg/ea_emitter/element/divider_renderer"
        autoload :AttributeRenderer, "ea/svg/ea_emitter/element/attribute_renderer"
        autoload :AttributeLineBuilder, "ea/svg/ea_emitter/element/attribute_line_builder"
        autoload :EnumerationLiteralRenderer, "ea/svg/ea_emitter/element/enumeration_literal_renderer"
        autoload :OperationRenderer, "ea/svg/ea_emitter/element/operation_renderer"
        autoload :TaggedValueRenderer, "ea/svg/ea_emitter/element/tagged_value_renderer"
        autoload :ConstraintRenderer, "ea/svg/ea_emitter/element/constraint_renderer"
        autoload :CompartmentGeometry, "ea/svg/ea_emitter/element/compartment_geometry"
        autoload :IconRenderer, "ea/svg/ea_emitter/element/icon_renderer"
        autoload :StereotypeIconRenderer, "ea/svg/ea_emitter/element/stereotype_icon_renderer"
        autoload :RowIconRenderer, "ea/svg/ea_emitter/element/row_icon_renderer"
        autoload :HandDrawShapeRenderer, "ea/svg/ea_emitter/element/hand_draw_shape_renderer"
        autoload :LegendRenderer, "ea/svg/ea_emitter/element/legend_renderer"
      end
    end
  end
end
