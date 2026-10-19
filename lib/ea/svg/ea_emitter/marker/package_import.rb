# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Marker
        # PackageImport marker for «import» connectors between
        # packages. EA draws the dependency-style open arrowhead at the
        # target (imported) end, whether or not the diagram link
        # carries explicit SX/SY offsets.
        class PackageImport < Kind
          def self.handles?(effective_type)
            effective_type == "Package"
          end

          def self.specs_for(_connector, _source, target, before_target, _after_source, **)
            [Registry::Spec.new(shape: :dependency_arrow,
                                anchor: target, base: before_target)]
          end
        end
      end
    end
  end
end

Ea::Svg::EaEmitter::Marker::Registry.register(Ea::Svg::EaEmitter::Marker::PackageImport)
