# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Marker
        # PackageImport marker for «import» connectors between
        # packages. EA draws a closed trapezoid silhouette at the
        # source end (the importing package) and an open V-arrow at
        # the target end (the imported package) — but ONLY when the
        # connector's geometry string carries explicit SX/SY offset
        # fields. Auto-routed connectors (no SX/SY) render as a
        # plain solid line with no package_anchor marker.
        #
        # Verified against both QEAs (output by the same EA run):
        #   - basic.qea Package Imports: SX=0;SY=0 present → marker
        #   - plateau Urban Planning ADE2: SX/SY absent → no marker
        class PackageImport < Kind
          def self.handles?(effective_type)
            effective_type == "Package"
          end

          def self.specs_for(connector, source, target, before_target, after_source, relationship: nil)
            return [] unless connector.has_geometry_offsets

            [
              Registry::Spec.new(shape: :package_anchor,
                                 anchor: source, base: after_source),
              Registry::Spec.new(shape: :arrow, anchor: target,
                                 base: before_target)
            ]
          end
        end
      end
    end
  end
end

Ea::Svg::EaEmitter::Marker::Registry.register(Ea::Svg::EaEmitter::Marker::PackageImport)
