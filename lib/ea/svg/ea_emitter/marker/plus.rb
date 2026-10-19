# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Marker
        # Circled-plus marker at the container end of a Nesting
        # connector. EA draws a white circle of radius ARM_LENGTH just
        # outside the container edge with a plus (two crossed arms)
        # through its centre; the connector starts at the nested
        # element and ends at the container.
        #
        class Plus < Kind
          ARM_LENGTH = 8

          def self.handles?(effective_type)
            effective_type == "Nesting"
          end

          def self.specs_for(connector, source, target, before_target, after_source, relationship: nil)
            container_at_target = whole_end_at_source?(connector)
            anchor = container_at_target ? target : source
            base = container_at_target ? before_target : after_source
            [Registry::Spec.new(shape: :nesting, anchor: anchor, base: base)]
          end
        end
      end
    end
  end
end

Ea::Svg::EaEmitter::Marker::Registry.register(Ea::Svg::EaEmitter::Marker::Plus)
