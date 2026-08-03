# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Marker
        # Open triangle marker for UML generalization, realization,
        # and dependency. White-filled 3-point polygon at the
        # general / supplier end.
        class OpenTriangle < Kind
          def self.handles?(effective_type)
            %w[Generalization Realization Dependency].include?(effective_type)
          end

          def self.specs_for(connector, source, target, before_target, after_source, relationship: nil)
            whole_end_at_source = whole_end_at_source?(connector)
            anchor = whole_end_at_source ? target : source
            base = whole_end_at_source ? before_target : after_source
            [Registry::Spec.new(shape: :triangle, anchor: anchor, base: base)]
          end
        end
      end
    end
  end
end

Ea::Svg::EaEmitter::Marker::Registry.register(Ea::Svg::EaEmitter::Marker::OpenTriangle)
