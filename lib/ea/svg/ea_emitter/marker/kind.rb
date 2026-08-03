# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Marker
        # Base class for marker kinds. Subclasses declare which
        # connector types they handle and produce Spec instances
        # describing the marker geometry.
        class Kind
          # Returns true if this kind handles the given effective
          # connector type (e.g. "Aggregation", "Generalization").
          def self.handles?(_effective_type)
            false
          end

          # Returns an Array of Spec instances describing the
          # markers to emit. Each Spec has :shape, :anchor, :base.
          # `relationship` is the resolved relationship model (e.g.
          # Association) when available, nil otherwise.
          def self.specs_for(_connector, _source, _target,
                             _before_target, _after_source, relationship: nil)
            []
          end

          # Common helper: "destination → source" direction means
          # the whole end of an aggregation is at the target end.
          def self.whole_end_at_source?(connector)
            connector.direction != "Destination -> Source"
          end
        end
      end
    end
  end
end
