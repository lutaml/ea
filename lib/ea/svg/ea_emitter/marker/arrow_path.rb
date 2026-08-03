# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Marker
        # Navigability arrow at the target end of an association.
        # Rendered as a `<path>` (not polygon) sharing style with the
        # connector line. When both ends are navigable
        # (bidirectional association), EA renders a separate arrow at
        # each end.
        class ArrowPath < Kind
          def self.handles?(effective_type)
            effective_type == "Association"
          end

          def self.specs_for(connector, source, target, before_target,
                             after_source, relationship: nil)
            return bidirectional_specs(source, target, before_target,
                                       after_source) if bidirectional?(connector)

            whole_end_at_source = whole_end_at_source?(connector)
            anchor = whole_end_at_source ? target : source
            base = whole_end_at_source ? before_target : after_source
            [Registry::Spec.new(shape: :arrow, anchor: anchor, base: base)]
          end

          # EA marks truly bidirectional associations with
          # direction="Bi-Directional" on t_connector. These get a
          # separate arrow at each end. All other directions render
          # a single arrow at the navigable end.
          def self.bidirectional?(connector)
            connector.direction == "Bi-Directional"
          end
          private_class_method :bidirectional?

          def self.bidirectional_specs(source, target, before_target, after_source)
            [
              Registry::Spec.new(shape: :arrow, anchor: source,
                                 base: after_source),
              Registry::Spec.new(shape: :arrow, anchor: target,
                                 base: before_target)
            ]
          end
          private_class_method :bidirectional_specs
        end
      end
    end
  end
end

Ea::Svg::EaEmitter::Marker::Registry.register(Ea::Svg::EaEmitter::Marker::ArrowPath)
