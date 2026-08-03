# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Label
        # Dispatches a connector to the appropriate label renderer(s).
        #
        # Rules:
        #   - Any relationship with an applied stereotype renders
        #     «stereotype» at the midpoint (Associations included —
        #     «import» on a Package connector is a common case).
        #   - Associations without a stereotype render EndLabel at
        #     each positioned LLT/LRT box.
        #   - Other relationship kinds without a stereotype render
        #     nothing.
        #
        # Open/closed: a new label kind registers here rather than
        # forcing callers to edit case statements elsewhere.
        class Registry
          attr_reader :model_index

          def initialize(model_index:)
            @model_index = model_index
          end

          # Returns the formatted stereotype label when the
          # connector should render at the midpoint, nil otherwise.
          def midpoint?(connector)
            MidpointLabel.new(canvas: nil, model_index: model_index,
                              font_family: nil, font_size: nil,
                              font_unit: nil).stereotype_label(connector)
          end

          # Returns true if the connector's relationship is an
          # Association AND has no midpoint stereotype (the end-label
          # path).
          def end_label?(connector)
            association?(connector) && !midpoint?(connector)
          end

          def association?(connector)
            rel = model_index ? model_index[connector.relationship_ref] : nil
            rel.is_a?(Ea::Model::Association)
          end
        end
      end
    end
  end
end
