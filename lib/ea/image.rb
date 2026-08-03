# frozen_string_literal: true

module Ea
  # Image rendering namespace. Converts EA's t_image EMF blobs to SVG.
  #
  # The emfsvg gem is an OPTIONAL runtime dependency. If it isn't
  # loadable, callers degrade gracefully (image is skipped). This
  # keeps the ea gem usable without forcing emfsvg on every install.
  module Image
    autoload :EmfRenderer, "ea/image/emf_renderer"
  end
end
