# frozen_string_literal: true

module Ea
  module Theme
    # Loads theme Definition objects from YAML files.
    #
    # YAML format (see config/themes/119.yml):
    #
    #   id: "119"
    #   name: EA White Theme
    #   font: { family: Carlito, size: 7, unit: pt, weight_normal: 400, ... }
    #   element_font: { size: 9, unit: pt }
    #   colors: { text: "#000000", attribute_text: "#66413F", ... }
    #   strokes: { element_border: 2, connector_line: 2, ... }
    #   text_metrics: { width_factor: 0.65 }
    #   canvas: { inset_left: 35, inset_right: 50, ... }
    #   frame: { inset: 6, tab_height: 20, ... }
    #   compartments: { header_line_offset: 4, ... }
    #   attribute: { visibility_x_offset: 5, content_x_offset: 20 }
    #   markers: { diamond_half_width: 5, ... }
    #   package: { tab_height: 20, ... }
    #   note: { fold_size: 12, ... }
    #   fills: {}
    #
    class Loader
      class << self
        def load_file(path)
          data = YAML.load_file(path)
          from_hash(data)
        end

        def load_dir(dir)
          Dir.glob(File.join(dir, "*.yml")).map { |f| load_file(f) }
        end

        private

        def from_hash(data)
          font = data["font"] || {}
          elem_font = data["element_font"] || {}
          colors = data["colors"] || {}
          strokes = data["strokes"] || {}
          text_metrics = data["text_metrics"] || {}
          canvas = data["canvas"] || {}
          frame = data["frame"] || {}
          comps = data["compartments"] || {}
          attr_cfg = data["attribute"] || {}
          marker_cfg = data["markers"] || {}
          pkg_cfg = data["package"] || {}
          note_cfg = data["note"] || {}

          Definition.new(
            id: data["id"],
            name: data["name"],
            font_family: font["family"],
            font_size: font["size"],
            font_size_unit: font["unit"] || "pt",
            text_weight_normal: font["weight_normal"] || 400,
            text_weight_bold: font["weight_bold"] || 700,
            element_font_size: elem_font["size"] || 9,
            element_font_unit: elem_font["unit"] || "pt",
            text_color: colors["text"] || "#000000",
            attribute_text_color: colors["attribute_text"],
            method_text_color: colors["method_text"],
            border_color: colors["border"] || "#000000",
            fill_color: colors["fill"] || "#FFFFFF",
            background_color: colors["background"] || "#FFFFFF",
            stroke_in_text_color: colors["stroke_in_text"] || "#000000",
            element_border_width: strokes["element_border"] || 2,
            connector_line_width: strokes["connector_line"] || 2,
            divider_stroke_width: strokes["divider"] || 2,
            marker_stroke_width: strokes["marker"] || 2,
            text_width_factor: text_metrics["width_factor"] || 0.65,
            geometry: canvas.empty? ? nil : Definition::Geometry.new(
              inset_left: canvas["inset_left"] || 35,
              inset_right: canvas["inset_right"] || 50,
              inset_top: canvas["inset_top"] || 40,
              inset_bottom: canvas["inset_bottom"] || 57
            ),
            frame: frame.empty? ? nil : Definition::FrameSpec.new(
              inset: frame["inset"] || 6,
              tab_height: frame["tab_height"] || 20,
              tab_slant: frame["tab_slant"] || 13,
              tab_label_x: frame["tab_label_x"] || 11,
              tab_label_y: frame["tab_label_y"] || 19,
              tab_padding: frame["tab_padding"] || 7
            ),
            compartments: comps.empty? ? nil : Definition::CompartmentSpec.new(
              header_top_padding: comps["header_top_padding"] || 9,
              header_line_offset: comps["header_line_offset"] || 6,
              divider_offset: comps["divider_offset"] || 8,
              attr_line_offset: comps["attr_line_offset"] || 4,
              attr_first_offset: comps["attr_first_offset"] || 7,
              op_line_offset: comps["op_line_offset"] || 4
            ),
            attribute_spec: attr_cfg.empty? ? nil : Definition::AttrSpec.new(
              visibility_x_offset: attr_cfg["visibility_x_offset"] || 5,
              content_x_offset: attr_cfg["content_x_offset"] || 26
            ),
            markers: marker_cfg.empty? ? nil : Definition::MarkerSpec.new(
              diamond_half_width: marker_cfg["diamond_half_width"] || 5,
              diamond_half_height: marker_cfg["diamond_half_height"] || 10,
              triangle_half_base: marker_cfg["triangle_half_base"] || 6,
              triangle_height: marker_cfg["triangle_height"] || 11,
              arrow_half_base: marker_cfg["arrow_half_base"] || 6,
              arrow_height: marker_cfg["arrow_height"] || 11
            ),
            package: pkg_cfg.empty? ? nil : Definition::PackageSpec.new(
              tab_height: pkg_cfg["tab_height"] || 20,
              tab_label_padding: pkg_cfg["tab_label_padding"] || 10,
              default_tab_width: pkg_cfg["default_tab_width"] || 105
            ),
            note: note_cfg.empty? ? nil : Definition::NoteSpec.new(
              fold_size: note_cfg["fold_size"] || 12,
              text_x_offset: note_cfg["text_x_offset"] || 5,
              text_y_offset: note_cfg["text_y_offset"] || 12,
              line_height: note_cfg["line_height"] || 12
            ),
            fills: data["fills"] || {}
          )
        end
      end
    end
  end
end
