# frozen_string_literal: true

module Ea
  module Theme
    # Loads theme YAML files into Ea::Theme::Definition.
    #
    # The YAML wire shape is parsed by {ThemeDocument} through
    # lutaml-model mappings (group classes declared under Definition);
    # this loader flattens the parsed groups into Definition
    # constructor arguments, applying the same group coalescing
    # defaults the renderer contract has always used.
    class Loader
      class << self
        def load_file(path)
          from_document(ThemeDocument.from_yaml(File.read(path)))
        end

        def load_dir(dir)
          Dir.glob(File.join(dir, "*.yml")).map { |f| load_file(f) }
        end

        private

        def from_document(doc)
          font = doc.font || Definition::FontSpec.new
          label_font = doc.label_font || Definition::FontSpec.new
          element_font = doc.element_font || Definition::FontSpec.new
          colors = doc.colors || Definition::ColorsSpec.new
          strokes = doc.strokes || Definition::StrokesSpec.new
          text_metrics = doc.text_metrics || Definition::TextMetricsSpec.new

          Definition.new(
            id: doc.id,
            name: doc.name,
            font_family: font.family,
            label_font_family: label_font.family,
            label_font_size: label_font.size,
            label_font_size_unit: label_font.unit,
            font_size: font.size,
            font_size_unit: font.unit || "pt",
            text_weight_normal: font.weight_normal || 400,
            text_weight_bold: font.weight_bold || 700,
            element_font_family: element_font.family,
            element_font_size: element_font.size || 9,
            element_font_unit: element_font.unit || "pt",
            text_color: colors.text || "#000000",
            attribute_text_color: colors.attribute_text || colors.text || "#000000",
            method_text_color: colors.method_text,
            border_color: colors.border || "#000000",
            fill_color: colors.fill || "#FFFFFF",
            background_color: colors.background || "#FFFFFF",
            stroke_in_text_color: colors.stroke_in_text || "#000000",
            element_border_width: strokes.element_border || 2,
            connector_line_width: strokes.connector_line || 2,
            divider_stroke_width: strokes.divider || 2,
            marker_stroke_width: strokes.marker || 2,
            text_width_factor: text_metrics.width_factor || 0.65,
            geometry: geometry_from(doc.canvas),
            frame: frame_from(doc.frame),
            compartments: compartments_from(doc.compartments),
            attribute_spec: attribute_spec_from(doc.attribute),
            markers: markers_from(doc.markers),
            package: package_from(doc.package),
            note: note_from(doc.note),
            fills: doc.fills || {}
          )
        end

        def geometry_from(canvas)
          return unless canvas

          Definition::Geometry.new(
            inset_left: canvas.inset_left || 35,
            inset_right: canvas.inset_right || 50,
            inset_top: canvas.inset_top || 40,
            inset_bottom: canvas.inset_bottom || 57
          )
        end

        def frame_from(frame)
          return unless frame

          Definition::FrameSpec.new(
            inset: frame.inset || 6,
            tab_height: frame.tab_height || 20,
            tab_slant: frame.tab_slant || 13,
            tab_label_x: frame.tab_label_x || 11,
            tab_label_y: frame.tab_label_y || 19,
            tab_padding: frame.tab_padding || 7
          )
        end

        def compartments_from(comps)
          return unless comps

          Definition::CompartmentSpec.new(
            header_top_padding: comps.header_top_padding || 12,
            header_line_offset: comps.header_line_offset || 6,
            divider_offset: comps.divider_offset || 8,
            attr_line_offset: comps.attr_line_offset || 7,
            attr_first_offset: comps.attr_first_offset || 7,
            op_line_offset: comps.op_line_offset || 4
          )
        end

        def attribute_spec_from(attr_cfg)
          return unless attr_cfg

          Definition::AttrSpec.new(
            visibility_x_offset: attr_cfg.visibility_x_offset || 5,
            content_x_offset: attr_cfg.content_x_offset || 26
          )
        end

        def markers_from(marker_cfg)
          return unless marker_cfg

          Definition::MarkerSpec.new(
            diamond_half_width: marker_cfg.diamond_half_width || 5,
            diamond_half_height: marker_cfg.diamond_half_height || 10,
            triangle_half_base: marker_cfg.triangle_half_base || 6,
            triangle_height: marker_cfg.triangle_height || 11,
            arrow_half_base: marker_cfg.arrow_half_base || 6,
            arrow_height: marker_cfg.arrow_height || 11
          )
        end

        def package_from(pkg_cfg)
          return unless pkg_cfg

          Definition::PackageSpec.new(
            tab_height: pkg_cfg.tab_height || 20,
            tab_label_padding: pkg_cfg.tab_label_padding || 10,
            default_tab_width: pkg_cfg.default_tab_width || 105
          )
        end

        def note_from(note_cfg)
          return unless note_cfg

          Definition::NoteSpec.new(
            fold_size: note_cfg.fold_size || 12,
            text_x_offset: note_cfg.text_x_offset || 5,
            text_y_offset: note_cfg.text_y_offset || 12,
            line_height: note_cfg.line_height || 12
          )
        end
      end
    end
  end
end
