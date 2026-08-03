# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Marker dispatch registry. Each `Kind` subclass handles one
      # connector type (or family) and produces the marker specs.
      # Adding a new marker kind = creating a class + registering
      # it (OCP).
      module Marker
        autoload :Kind, "ea/svg/ea_emitter/marker/kind"
        autoload :Registry, "ea/svg/ea_emitter/marker/registry"
        autoload :Diamond, "ea/svg/ea_emitter/marker/diamond"
        autoload :OpenTriangle, "ea/svg/ea_emitter/marker/open_triangle"
        autoload :ArrowPath, "ea/svg/ea_emitter/marker/arrow_path"
        autoload :Plus, "ea/svg/ea_emitter/marker/plus"
        autoload :PackageImport, "ea/svg/ea_emitter/marker/package_import"

        # Built-in marker kinds register themselves at the bottom of
        # their respective files. Referencing each constant here
        # forces autoload, which runs the per-file registration lines.
        # Diamond first so "Aggregation" wins over generic fallback.
        def self.ensure_builtins_registered!
          # Touch the constants to trigger autoload + registration.
          # Each constant is autoloaded, so merely referencing it
          # causes the file to load. Registration lines at the
          # bottom of each file then add the kind to the Registry.
          Diamond
          OpenTriangle
          Plus
          ArrowPath
          PackageImport
        end
      end
    end
  end
end
