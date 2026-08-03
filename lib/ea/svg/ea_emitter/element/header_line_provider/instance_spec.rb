# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        module HeaderLineProvider
          # InstanceSpecification: short-circuits the pipeline. The
          # entire header for an instance is "name: Classifier" on
          # one bold line. No stereotype, no wrap, no parent ghost.
          class InstanceSpec
            def self.call(context)
              inst = context.classifier
              return [] unless inst.is_a?(Ea::Model::InstanceSpecification)

              label = inst.name.to_s
              if inst.classifier_name && !inst.classifier_name.empty?
                label = "#{label}: #{inst.classifier_name}"
              end
              [[label, :bold]]
            end
          end
        end
      end
    end
  end
end
