# frozen_string_literal: true

module Ea
  module Theme
    # Immutable value object describing a complete EA diagram theme.
    #
    # Bundles ALL appearance values that EA's SVG renderer needs:
    # fonts, colors, strokes, canvas insets, compartment spacing,
    # marker geometry, etc. No renderer hardcodes appearance
    # numbers — every value comes from the active Definition.
    #
    # The nested group classes below are lutaml-model Serializable:
    # they are the declared wire shapes parsed by ThemeDocument from
    # config/themes/*.yml. Values are nil-able here — group-level
    # coalescing defaults are applied by the Loader when flattening
    # into Definition.
    class Definition
      class FontSpec < Lutaml::Model::Serializable
        attribute :family, :string
        attribute :size, :integer
        attribute :unit, :string
        attribute :weight_normal, :integer
        attribute :weight_bold, :integer

        yaml do
          map "family", to: :family
          map "size", to: :size
          map "unit", to: :unit
          map "weight_normal", to: :weight_normal
          map "weight_bold", to: :weight_bold
        end
      end

      class ColorsSpec < Lutaml::Model::Serializable
        attribute :text, :string
        attribute :attribute_text, :string
        attribute :method_text, :string
        attribute :border, :string
        attribute :fill, :string
        attribute :background, :string
        attribute :stroke_in_text, :string

        yaml do
          map "text", to: :text
          map "attribute_text", to: :attribute_text
          map "method_text", to: :method_text
          map "border", to: :border
          map "fill", to: :fill
          map "background", to: :background
          map "stroke_in_text", to: :stroke_in_text
        end
      end

      class StrokesSpec < Lutaml::Model::Serializable
        attribute :element_border, :integer
        attribute :connector_line, :integer
        attribute :divider, :integer
        attribute :marker, :integer

        yaml do
          map "element_border", to: :element_border
          map "connector_line", to: :connector_line
          map "divider", to: :divider
          map "marker", to: :marker
        end
      end

      class TextMetricsSpec < Lutaml::Model::Serializable
        attribute :width_factor, :float

        yaml do
          map "width_factor", to: :width_factor
        end
      end

      class Geometry < Lutaml::Model::Serializable
        attribute :inset_left, :integer
        attribute :inset_right, :integer
        attribute :inset_top, :integer
        attribute :inset_bottom, :integer

        yaml do
          map "inset_left", to: :inset_left
          map "inset_right", to: :inset_right
          map "inset_top", to: :inset_top
          map "inset_bottom", to: :inset_bottom
        end
      end

      class FrameSpec < Lutaml::Model::Serializable
        attribute :inset, :integer
        attribute :tab_height, :integer
        attribute :tab_slant, :integer
        attribute :tab_label_x, :integer
        attribute :tab_label_y, :integer
        attribute :tab_padding, :integer

        yaml do
          map "inset", to: :inset
          map "tab_height", to: :tab_height
          map "tab_slant", to: :tab_slant
          map "tab_label_x", to: :tab_label_x
          map "tab_label_y", to: :tab_label_y
          map "tab_padding", to: :tab_padding
        end
      end

      class CompartmentSpec < Lutaml::Model::Serializable
        attribute :header_top_padding, :integer
        attribute :header_line_offset, :integer
        attribute :divider_offset, :integer
        attribute :attr_line_offset, :integer
        attribute :attr_first_offset, :integer
        attribute :op_line_offset, :integer

        yaml do
          map "header_top_padding", to: :header_top_padding
          map "header_line_offset", to: :header_line_offset
          map "divider_offset", to: :divider_offset
          map "attr_line_offset", to: :attr_line_offset
          map "attr_first_offset", to: :attr_first_offset
          map "op_line_offset", to: :op_line_offset
        end
      end

      class AttrSpec < Lutaml::Model::Serializable
        attribute :visibility_x_offset, :integer
        attribute :content_x_offset, :integer

        yaml do
          map "visibility_x_offset", to: :visibility_x_offset
          map "content_x_offset", to: :content_x_offset
        end
      end

      class MarkerSpec < Lutaml::Model::Serializable
        attribute :diamond_half_width, :integer
        attribute :diamond_half_height, :integer
        attribute :triangle_half_base, :integer
        attribute :triangle_height, :integer
        attribute :arrow_half_base, :integer
        attribute :arrow_height, :integer

        yaml do
          map "diamond_half_width", to: :diamond_half_width
          map "diamond_half_height", to: :diamond_half_height
          map "triangle_half_base", to: :triangle_half_base
          map "triangle_height", to: :triangle_height
          map "arrow_half_base", to: :arrow_half_base
          map "arrow_height", to: :arrow_height
        end
      end

      class PackageSpec < Lutaml::Model::Serializable
        attribute :tab_height, :integer
        attribute :tab_label_padding, :integer
        attribute :default_tab_width, :integer

        yaml do
          map "tab_height", to: :tab_height
          map "tab_label_padding", to: :tab_label_padding
          map "default_tab_width", to: :default_tab_width
        end
      end

      class NoteSpec < Lutaml::Model::Serializable
        attribute :fold_size, :integer
        attribute :text_x_offset, :integer
        attribute :text_y_offset, :integer
        attribute :line_height, :integer

        yaml do
          map "fold_size", to: :fold_size
          map "text_x_offset", to: :text_x_offset
          map "text_y_offset", to: :text_y_offset
          map "line_height", to: :line_height
        end
      end

      attr_reader :id, :name,
                  :font_family, :font_size, :font_size_unit,
                  :text_weight_normal, :text_weight_bold,
                  :element_font_family, :element_font_size, :element_font_unit,
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
      DEFAULT_COMPARTMENTS = CompartmentSpec.new(header_top_padding: 12,
                                                 header_line_offset: 6,
                                                 divider_offset: 8,
                                                 attr_line_offset: 6,
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
                                  text_y_offset: 12, line_height: 13).freeze

      def initialize(id:, name: nil, font_family: nil, font_size: nil,
                     label_font_family: nil, label_font_size: nil,
                     label_font_size_unit: nil,
                     font_size_unit: "pt", text_weight_normal: 400,
                     text_weight_bold: 700,
                     element_font_family: nil, element_font_size: 9, element_font_unit: "pt",
                     text_color: "#000000", attribute_text_color: nil,
                     method_text_color: nil, border_color: "#000000",
                     fill_color: "#FFFFFF", background_color: "#FFFFFF",
                     stroke_in_text_color: "#000000",
                     element_border_width: 2, connector_line_width: 2,
                     divider_stroke_width: 2, marker_stroke_width: 2,
                     text_width_factor: 0.612,
                     geometry: nil, frame: nil, compartments: nil,
                     attribute_spec: nil, markers: nil, package: nil,
                     note: nil, fills: {})
        @id = id.to_s
        @name = name
        @font_family = font_family
        @label_font_family = label_font_family
        @label_font_size = label_font_size
        @label_font_size_unit = label_font_size_unit
        @font_size = font_size
        @font_size_unit = font_size_unit
        @text_weight_normal = text_weight_normal
        @text_weight_bold = text_weight_bold
        @element_font_family = element_font_family
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
        @attribute_spec_override = attribute_spec
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

      def label_font_family
        @label_font_family || font_family
      end

      def label_font_size
        @label_font_size || font_size
      end

      def label_font_size_unit
        @label_font_size_unit || font_size_unit
      end

      # Content x of attribute and enum-literal names; a theme's own
      # attribute_spec overrides the inherited seat.
      def attribute_content_x_offset
        @attribute_spec_override ? attribute_spec.content_x_offset : 22
      end

      def with(**overrides)
        clear_label_override(overrides, :font_family, :label_font_family)
        clear_label_override(overrides, :font_family, :element_font_family)
        clear_label_override(overrides, :font_size, :label_font_size)
        clear_label_override(overrides, :font_size_unit, :label_font_size_unit)
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
          label_font_family: @label_font_family,
          label_font_size: @label_font_size,
          label_font_size_unit: @label_font_size_unit,
          text_weight_normal: text_weight_normal,
          text_weight_bold: text_weight_bold,
          element_font_family: element_font_family,
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
          # Preserve omission so reconstruction retains the attribute-cell default.
          attribute_spec: @attribute_spec_override, markers: markers,
          package: package, note: note, fills: fills
        }
      end

      private

      def clear_label_override(overrides, global_key, label_key)
        overrides[label_key] = nil if overrides.key?(global_key) && !overrides.key?(label_key)
      end
    end
  end
end
