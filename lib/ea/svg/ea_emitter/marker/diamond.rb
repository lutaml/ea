# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Marker
        # Diamond marker at the whole end of an aggregation or
        # composition, PLUS a navigability arrow at the part end
        # when the connector's direction is "Destination -> Source".
        # Reference SVGs confirm EA emits BOTH markers for
        # reverse-direction aggregations on the plateau: the diamond
        # distinguishes aggregation from association, the arrow shows
        # navigability direction. Forward-direction ("Source ->
        # Destination") aggregations get the diamond only — verified
        # against basic.qea's "Two Level Class Composition Hierarchy"
        # diagram, where the reference SVG has 17 diamonds and 0
        # arrows.
        class Diamond < Kind
          def self.handles?(effective_type)
            effective_type == "Aggregation" || effective_type == "Composition"
          end

          def self.specs_for(connector, source, target, before_target, after_source, relationship: nil)
            whole_end_at_source = whole_end_at_source?(connector)
            whole_anchor = whole_end_at_source ? source : target
            whole_base = whole_end_at_source ? after_source : before_target
            specs = [Registry::Spec.new(shape: :diamond,
                                        anchor: whole_anchor,
                                        base: whole_base)]
            return specs unless navigable_part_end?(connector)

            part_anchor = whole_end_at_source ? target : source
            part_base = whole_end_at_source ? before_target : after_source
            specs << Registry::Spec.new(shape: :arrow,
                                        anchor: part_anchor,
                                        base: part_base)
            specs
          end

          # EA renders the navigability arrow at the part end of an
          # aggregation only when the connector's direction is
          # "Destination -> Source" — the conventional EA encoding
          # for "part -> whole" with navigability back to the whole.
          # Forward-direction aggregations ("Source -> Destination")
          # omit the arrow: the diamond already communicates the
          # aggregation semantic and the destination is not
          # explicitly navigable.
          def self.navigable_part_end?(connector)
            connector.direction == "Destination -> Source"
          end
        end
      end
    end
  end
end

Ea::Svg::EaEmitter::Marker::Registry.register(Ea::Svg::EaEmitter::Marker::Diamond)
