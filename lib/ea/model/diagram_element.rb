# frozen_string_literal: true

module Ea
  module Model
    # A single placed element on a diagram. References the model
    # element it visualizes (by id), carries pixel bounds and a
    # parsed style map (fill color, line color, font, etc.).
    #
    # Carries two distinct bounds:
    # - `bounds` — logical rect (EA's Left/Top/Right/Bottom)
    # - `image_bounds` — visual rect including padding (EA's
    #   imgL/imgT/imgR/imgB); used by EA's SVG renderer for the
    #   actual `<rect>` width/height
    class DiagramElement < Base
      attribute :diagram_id, :string
      attribute :model_element_ref, :string # id of Classifier/Package/etc.
      attribute :bounds, Bounds
      attribute :image_bounds, Bounds
      attribute :style, :hash, default: -> { {} } # parsed style fields
      attribute :background_color, :integer # EA BGR integer
      attribute :line_color, :integer
      attribute :line_width, :integer
      attribute :font_family, :string
      attribute :font_size, :integer
      attribute :font_bold, :boolean
      attribute :font_italic, :boolean
      attribute :font_underline, :boolean
      attribute :show_tagged_values, :boolean
      # EA's per-element "HideIcon" flag — tri-state:
      #   "shown"  → HideIcon=0, render the type icon
      #   "hidden" → HideIcon=1, suppress the type icon
      #   nil      → not set in source; renderer applies the
      #              diagram default (typically hidden).
      attribute :icon_visibility, :string
      attribute :z_order, :integer # seqno
      attribute :duid, :string # EA's per-placement DUID for connector resolution
      # UMLDI keyword text EA emitted for this shape (e.g. "Type",
      # "FeatureType"). When present, this is the authoritative
      # label EA rendered in the SVG header — the source XMI is
      # canonical. Falls back to the classifier's stereotype when
      # absent (basic.qea has no UMLDI metadata).
      attribute :umldi_keyword, :string

      json do
        map "id", to: :id
        map "diagramId", to: :diagram_id
        map "modelElementRef", to: :model_element_ref
        map "bounds", to: :bounds
        map "imageBounds", to: :image_bounds
        map "style", to: :style
        map "backgroundColor", to: :background_color
        map "lineColor", to: :line_color
        map "lineWidth", to: :line_width
        map "fontFamily", to: :font_family
        map "fontSize", to: :font_size
        map "fontBold", to: :font_bold, render_default: true
        map "fontItalic", to: :font_italic, render_default: true
        map "fontUnderline", to: :font_underline, render_default: true
        map "showTaggedValues", to: :show_tagged_values, render_default: true
        map "iconVisibility", to: :icon_visibility
        map "zOrder", to: :z_order
        map "duid", to: :duid
        map "umldiKeyword", to: :umldi_keyword
      end
    end
  end
end
