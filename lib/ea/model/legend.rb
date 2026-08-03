# frozen_string_literal: true

module Ea
  module Model
    # An auto-generated legend block. EA emits these from a
    # `t_object` row of Object_Type="Text" whose StyleEx carries
    # `LegendOpts=...`. The visible block — title, colored icon
    # rects, and per-item labels — is configured by a sibling
    # `t_xref` row of name="CustomProperties" on the same GUID.
    #
    # Colors are stored as EA's BGR-packed integers (same encoding
    # as t_object.BCol). Convert to "#RRGGBB" at render time via
    # Ea::Svg::EaEmitter::Element::BColDecoder.
    class Legend < Base
      DEFAULT_TITLE = "凡例"
      DEFAULT_HEADING_SIZE = 12
      DEFAULT_ITEM_SIZE = 9
      DEFAULT_FONT_COLOR = 0x603000     # BGR for #003060
      DEFAULT_BACKGROUND_COLOR = 0xF0F0F0 # BGR for #F0F0F0
      DEFAULT_BORDER_COLOR = 0xD7D7D7     # BGR for #D7D7D7

      attribute :title, :string, default: -> { DEFAULT_TITLE }
      attribute :heading_size, :integer
      attribute :font_color, :integer, default: -> { DEFAULT_FONT_COLOR }
      attribute :background_color, :integer, default: -> { DEFAULT_BACKGROUND_COLOR }
      attribute :border_color, :integer, default: -> { DEFAULT_BORDER_COLOR }
      attribute :background_is_default, :boolean, default: -> { true }
      attribute :items, LegendItem, collection: true, initialize_empty: true

      json do
        map "id", to: :id
        map "name", to: :name
        map "title", to: :title
        map "headingSize", to: :heading_size
        map "fontColor", to: :font_color
        map "backgroundColor", to: :background_color
        map "borderColor", to: :border_color
        map "backgroundIsDefault", to: :background_is_default
        map "items", to: :items, render_empty: true
      end
    end
  end
end
