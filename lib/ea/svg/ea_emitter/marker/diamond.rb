# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Marker
        # Diamond marker at the whole end of an aggregation, plus a
        # navigability arrow apexing at the diamond's line-side tip.
        #
        # WHOLE-END SELECTION: EA flags the whole end either through
        # t_connector.DestAccess (1 shared / 2 composite -> whole at
        # the TARGET; corpus-verified 333EFCCF: PersonalRight_E is
        # the DestAccess=2 end and every diamond sits there) or
        # through the Connector_Type itself ("Aggregation"/
        # "Composition" -> whole at the SOURCE; basic.qea's
        # composition diagram). DestAccess wins when both appear.
        # Without relationship data the direction heuristic applies
        # ("Destination -> Source" -> whole at target).
        #
        # ARROW: dest-flagged aggregations draw a base-12 height-15
        # open arrow stacked on the diamond tip pointing into the
        # whole (333EFCCF: 6 diamonds + 6 path arrows). Type-inferred
        # source-side aggregations draw the diamond only (basic.qea:
        # 17 diamonds, 0 arrows).
        class Diamond < Kind
          def self.handles?(effective_type)
            effective_type == "Aggregation" || effective_type == "Composition"
          end

          def self.specs_for(connector, source, target, before_target, after_source, relationship: nil)
            whole_at_target = whole_at_target?(connector, relationship)
            whole_anchor = whole_at_target ? target : source
            whole_base = whole_at_target ? before_target : after_source
            specs = [Registry::Spec.new(shape: :diamond,
                                        anchor: whole_anchor,
                                        base: whole_base)]
            return specs unless whole_at_target

            specs << Registry::Spec.new(shape: :arrow,
                                        anchor: whole_anchor,
                                        base: whole_base)
            specs
          end

          def self.whole_at_target?(connector, relationship)
            return true if dest_flagged?(relationship)
            return false if source_flagged?(relationship)

            !whole_end_at_source?(connector)
          end

          def self.dest_flagged?(relationship)
            relationship &&
              %w[shared composite].include?(relationship.target_aggregation.to_s)
          end

          def self.source_flagged?(relationship)
            relationship &&
              %w[shared composite].include?(relationship.source_aggregation.to_s)
          end
        end
      end
    end
  end
end

Ea::Svg::EaEmitter::Marker::Registry.register(Ea::Svg::EaEmitter::Marker::Diamond)
