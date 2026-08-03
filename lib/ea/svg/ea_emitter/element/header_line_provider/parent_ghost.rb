# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        module HeaderLineProvider
          # Emits the off-canvas parent classifier name as the first
          # italic line. EA renders this when HideParents=0 and the
          # classifier's generalization parent is not placed on the
          # diagram.
          class ParentGhost
            # @param context [HeaderLinePipeline::Context]
            def self.call(context)
              name = context.off_canvas_parent_name
              return [] unless name

              [[name, :italic]]
            end
          end
        end
      end
    end
  end
end
