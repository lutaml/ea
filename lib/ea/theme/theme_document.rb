# frozen_string_literal: true

require "lutaml/model"

module Ea
  module Theme
    # Framework-declared YAML wire mapping for theme files.
    #
    # Theme files group values under keys (font/colors/strokes/…)
    # while Ea::Theme::Definition flattens them into constructor
    # arguments. This document parses the nested wire shape through
    # lutaml-model mappings (see the group spec classes under
    # Definition); Loader flattens the parsed groups into Definition
    # arguments and applies the group coalescing defaults.
    class ThemeDocument < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :name, :string
      attribute :font, Definition::FontSpec
      attribute :label_font, Definition::FontSpec
      attribute :element_font, Definition::FontSpec
      attribute :colors, Definition::ColorsSpec
      attribute :strokes, Definition::StrokesSpec
      attribute :text_metrics, Definition::TextMetricsSpec
      attribute :canvas, Definition::Geometry
      attribute :frame, Definition::FrameSpec
      attribute :compartments, Definition::CompartmentSpec
      attribute :attribute, Definition::AttrSpec
      attribute :markers, Definition::MarkerSpec
      attribute :package, Definition::PackageSpec
      attribute :note, Definition::NoteSpec
      attribute :fills, :hash

      yaml do
        map "id", to: :id
        map "name", to: :name
        map "font", to: :font
        map "label_font", to: :label_font
        map "element_font", to: :element_font
        map "colors", to: :colors
        map "strokes", to: :strokes
        map "text_metrics", to: :text_metrics
        map "canvas", to: :canvas
        map "frame", to: :frame
        map "compartments", to: :compartments
        map "attribute", to: :attribute
        map "markers", to: :markers
        map "package", to: :package
        map "note", to: :note
        map "fills", to: :fills
      end
    end
  end
end
