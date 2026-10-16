# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Marker
        # EA endpoint fields select the diamond end; direction selects
        # the arrow end for target-owned aggregations.
        class Diamond < Kind
          def self.handles?(effective_type)
            %w[Aggregation Composition].include?(effective_type)
          end

          def self.specs_for(connector, source, target, before_target, after_source, relationship: nil)
            whole_at_target = whole_at_target?(connector, relationship)
            whole_anchor = whole_at_target ? target : source
            whole_base = whole_at_target ? before_target : after_source
            specs = [Registry::Spec.new(shape: :diamond,
                                        anchor: whole_anchor,
                                        base: whole_base)]
            return specs unless whole_at_target

            specs.concat(direction_specs(connector, source, target,
                                         before_target, after_source))
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

          def self.direction_specs(connector, source, target, before_target,
                                   after_source)
            if connector.direction == "Destination -> Source"
              return [Registry::Spec.new(shape: :arrow, anchor: source,
                                         base: after_source)]
            end

            [Registry::Spec.new(shape: :arrow, anchor: target,
                                base: before_target)]
          end
          private_class_method :direction_specs
        end
      end
    end
  end
end

Ea::Svg::EaEmitter::Marker::Registry.register(Ea::Svg::EaEmitter::Marker::Diamond)
