# frozen_string_literal: true

module Ea
  # Conversion of SVG strings to raster/vector formats.
  # Delegates to external tools (rsvg-convert, headless Chrome) when
  # available; raises a clear error otherwise.
  module Render
    autoload :ImageConverter, "ea/render/image_converter"
  end
end
