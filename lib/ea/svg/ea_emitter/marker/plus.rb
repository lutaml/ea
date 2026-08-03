# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Marker
        # Plus-symbol marker at the contained end of a Nesting
        # connector. EA renders a "+" (16x16, two crossed lines)
        # at the end pointing INTO the container.
        #
        # Path encoding (two sub-paths in one <path>):
        #
        #   M cx cy-8 L cx cy+8    (vertical arm, 16 tall)
        #   M cx+8 cy L cx-8 cy    (horizontal arm, 16 wide)
        #
        # cx, cy = plus center, anchored at the source-end waypoint.
        class Plus < Kind
          ARM_LENGTH = 8

          def self.handles?(effective_type)
            effective_type == "Nesting"
          end

          def self.specs_for(connector, source, target, before_target, after_source, relationship: nil)
            # Plus is at the contained (child) end. EA's convention:
            # source end is the child, target end is the parent.
            # Default to source unless the connector direction
            # reverses the ends.
            whole_end_at_source = whole_end_at_source?(connector)
            anchor = whole_end_at_source ? source : target
            base = whole_end_at_source ? after_source : before_target
            [Registry::Spec.new(shape: :plus, anchor: anchor, base: base)]
          end
        end
      end
    end
  end
end

Ea::Svg::EaEmitter::Marker::Registry.register(Ea::Svg::EaEmitter::Marker::Plus)
