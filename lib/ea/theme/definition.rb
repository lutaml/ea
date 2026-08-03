# frozen_string_literal: true

module Ea
  module Theme
    # Immutable value object describing a complete EA diagram theme.
    #
    # Bundles ALL appearance values that EA's SVG renderer needs:
    # fonts, colors, strokes, canvas insets, compartment spacing,
    # marker geometry, etc. No renderer hardcodes appearance
    # numbers — every value comes from the active Definition.
    class Definition
      Geometry = Struct.new(:inset_left, :inset_right, :inset_top, :inset_bottom,
                             keyword_init: true)
      FrameSpec = Struct.new(:inset, :tab_height, :tab_slant, :tab_label_x,
                              :tab_label_y, :tab_padding, keyword_init: true)
      CompartmentSpec = Struct.new(:header_top_padding, :header_line_offset,
                                    :divider_offset, :attr_line_offset,
                                    :attr_first_offset, :op_line_offset,
                                    keyword_init: true)
      AttrSpec = Struct.new(:visibility_x_offset, :content_x_offset, keyword_init: true)
      MarkerSpec = Struct.new(:diamond_half_width, :diamond_half_height,
                               :triangle_half_base, :triangle_height,
                               :arrow_half_base, :arrow_height, keyword_init: true)
      PackageSpec = Struct.new(:tab_height, :tab_label_padding, :default_tab_width,
                                keyword_init: true)
      NoteSpec = Struct.new(:fold_size, :text_x_offset, :text_y_offset,
                             :line_height, keyword_init: true)

      attr_reader :id, :name,
                  :font_family, :font_size, :font_size_unit,
                  :text_weight_normal, :text_weight_bold,
                  :element_font_size, :element_font_unit,
                  :text_color, :attribute_text_color, :method_text_color,
                  :border_color, :fill_color, :background_color,
                  :stroke_in_text_color,
                  :element_border_width, :connector_line_width,
                  :divider_stroke_width, :marker_stroke_width,
                  :text_width_factor,
                  :geometry, :frame, :compartments, :attribute_spec,
                  :markers, :package, :note, :fills

      DEFAULT_GEOMETRY = Geometry.new(inset_left: 35, inset_right: 50,
                                       inset_top: 40, inset_bottom: 57).freeze
      DEFAULT_FRAME = FrameSpec.new(inset: 6, tab_height: 20, tab_slant: 13,
                                     tab_label_x: 11, tab_label_y: 19,
                                     tab_padding: 7).freeze
      DEFAULT_COMPARTMENTS = CompartmentSpec.new(header_top_padding: 9,
                                                   header_line_offset: 6,
                                                   divider_offset: 8,
                                                   attr_line_offset: 4,
                                                   attr_first_offset: 7,
                                                   op_line_offset: 4).freeze
      DEFAULT_ATTR = AttrSpec.new(visibility_x_offset: 5,
                                    content_x_offset: 20).freeze
      DEFAULT_MARKERS = MarkerSpec.new(diamond_half_width: 5,
                                         diamond_half_height: 10,
                                         triangle_half_base: 6,
                                         triangle_height: 11,
                                         arrow_half_base: 6,
                                         arrow_height: 11).freeze
      DEFAULT_PACKAGE = PackageSpec.new(tab_height: 20,
                                          tab_label_padding: 10,
                                          default_tab_width: 105).freeze
      DEFAULT_NOTE = NoteSpec.new(fold_size: 12, text_x_offset: 5,
                                    text_y_offset: 12, line_height: 12).freeze

      def initialize(id:, name: nil, font_family: nil, font_size: nil,
                     font_size_unit: "pt", text_weight_normal: 400,
                     text_weight_bold: 700,
                     element_font_size: 9, element_font_unit: "pt",
                     text_color: "#000000", attribute_text_color: nil,
                     method_text_color: nil, border_color: "#000000",
                     fill_color: "#FFFFFF", background_color: "#FFFFFF",
                     stroke_in_text_color: "#000000",
                     element_border_width: 2, connector_line_width: 2,
                     divider_stroke_width: 2, marker_stroke_width: 2,
                     text_width_factor: 0.65,
                     geometry: nil, frame: nil, compartments: nil,
                     attribute_spec: nil, markers: nil, package: nil,
                     note: nil, fills: {})
        @id = id.to_s
        @name = name
        @font_family = font_family
        @font_size = font_size
        @font_size_unit = font_size_unit
        @text_weight_normal = text_weight_normal
        @text_weight_bold = text_weight_bold
        @element_font_size = element_font_size
        @element_font_unit = element_font_unit
        @text_color = text_color
        @attribute_text_color = attribute_text_color
        @method_text_color = method_text_color
        @border_color = border_color
        @fill_color = fill_color
        @background_color = background_color
        @stroke_in_text_color = stroke_in_text_color
        @element_border_width = element_border_width
        @connector_line_width = connector_line_width
        @divider_stroke_width = divider_stroke_width
        @marker_stroke_width = marker_stroke_width
        @text_width_factor = text_width_factor
        @geometry = geometry || DEFAULT_GEOMETRY.dup
        @frame = frame || DEFAULT_FRAME.dup
        @compartments = compartments || DEFAULT_COMPARTMENTS.dup
        @attribute_spec = attribute_spec || DEFAULT_ATTR.dup
        @markers = markers || DEFAULT_MARKERS.dup
        @package = package || DEFAULT_PACKAGE.dup
        @note = note || DEFAULT_NOTE.dup
        @fills = fills.dup.freeze
      end

      def themed?
        id != "default"
      end

      def fill_for(classifier)
        return nil if classifier.nil?

        fills[classifier.class.name]
      end

      def with(**overrides)
        Definition.new(**to_h.merge(overrides))
      end

      def ==(other)
        other.is_a?(Definition) && id == other.id
      end

      def hash
        id.hash
      end

      alias eql? ==

      # Backward-compatible aliases for renamed attributes.
      def stroke_width
        element_border_width
      end

      def attribute_color
        attribute_text_color
      end

      def method_color
        method_text_color
      end

      def to_h
        {
          id: id, name: name,
          font_family: font_family, font_size: font_size,
          font_size_unit: font_size_unit,
          text_weight_normal: text_weight_normal,
          text_weight_bold: text_weight_bold,
          element_font_size: element_font_size,
          element_font_unit: element_font_unit,
          text_color: text_color,
          attribute_text_color: attribute_text_color,
          method_text_color: method_text_color,
          border_color: border_color, fill_color: fill_color,
          background_color: background_color,
          stroke_in_text_color: stroke_in_text_color,
          element_border_width: element_border_width,
          connector_line_width: connector_line_width,
          divider_stroke_width: divider_stroke_width,
          marker_stroke_width: marker_stroke_width,
          text_width_factor: text_width_factor,
          geometry: geometry, frame: frame, compartments: compartments,
          attribute_spec: attribute_spec, markers: markers,
          package: package, note: note, fills: fills
        }
      end
    end
  end
end
