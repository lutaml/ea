# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Marker
        # EA endpoint fields select the diamond end and its fill (shared
        # is hollow, composite is solid); direction selects the arrow end
        # for target-owned aggregations.
        class Diamond < Kind
          def self.handles?(effective_type)
            %w[Aggregation Composition].include?(effective_type)
          end

          def self.specs_for(connector, source, target, before_target, after_source, relationship: nil)
            whole_at_target = whole_at_target?(connector, relationship)
            whole_anchor = whole_at_target ? target : source
            whole_base = whole_at_target ? before_target : after_source
            specs = [Registry::Spec.new(shape: diamond_shape(connector, relationship, whole_at_target),
                                        anchor: whole_anchor,
                                        base: whole_base)]
            return specs unless whole_at_target
            return specs if arrow_on_target_diamond?(connector, relationship)

            specs.concat(direction_specs(connector, source, target,
                                         before_target, after_source))
          end

          # Diamonds for the ends of a plain association that carry an
          # aggregate flag.
          def self.flagged_end_specs(relationship, source, target,
                                     before_target, after_source)
            return [] unless relationship

            { target_aggregation: [target, before_target],
              source_aggregation: [source, after_source] }.filter_map do |reader, (anchor, base)|
              shape = flagged_shape(relationship.public_send(reader))
              Registry::Spec.new(shape: shape, anchor: anchor, base: base) if shape
            end
          end

          def self.flagged_shape(kind)
            case kind.to_s
            when "shared" then :diamond_hollow
            when "composite" then :diamond
            end
          end
          private_class_method :flagged_shape

          def self.diamond_shape(connector, relationship, whole_at_target)
            kind = if relationship
                     whole_at_target ? relationship.target_aggregation : relationship.source_aggregation
                   end
            kind = type_default_kind(connector) if kind.to_s.empty? || kind.to_s == "none"
            kind.to_s == "shared" ? :diamond_hollow : :diamond
          end
          private_class_method :diamond_shape

          def self.type_default_kind(connector)
            connector.connector_type == "Composition" ? "composite" : "shared"
          end
          private_class_method :type_default_kind

          def self.whole_at_target?(connector, relationship)
            return true if dest_flagged?(relationship)
            return false if source_flagged?(relationship)

            !whole_end_at_source?(connector)
          end

          # EA draws no arrow where a directed, dest-flagged aggregation
          # would put it on its own target diamond.
          def self.arrow_on_target_diamond?(connector, relationship)
            connector.direction == "Source -> Destination" &&
              dest_flagged?(relationship)
          end
          private_class_method :arrow_on_target_diamond?

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
