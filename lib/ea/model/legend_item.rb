# frozen_string_literal: true

module Ea
  module Model
    # One item in an auto-generated legend block: a colored icon
    # paired with a label string. The background_color is the icon's
    # fill, encoded as EA's BGR-packed integer (same encoding as
    # t_object.BCol). sort_index is the 0-based display order.
    class LegendItem < Base
      attribute :name, :string
      attribute :background_color, :integer
      attribute :pen_color, :integer, default: -> { 0 }
      attribute :pen_size, :integer, default: -> { 1 }
      attribute :sort_index, :integer, default: -> { 0 }

      json do
        map "id", to: :id
        map "name", to: :name
        map "backgroundColor", to: :background_color
        map "penColor", to: :pen_color
        map "penSize", to: :pen_size
        map "sortIndex", to: :sort_index
      end
    end
  end
end
