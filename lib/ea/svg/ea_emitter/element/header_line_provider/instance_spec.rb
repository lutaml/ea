# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        module HeaderLineProvider
          # InstanceSpecification: short-circuits the pipeline. The
          # header for an instance is "name: Classifier" on one bold
          # line, word-wrapped when it overflows the box (81F92FC7:
          # "new ownership:" / "LA_Right").
          class InstanceSpec
            def self.call(context)
              inst = context.classifier
              return [] unless inst.is_a?(Ea::Model::InstanceSpecification)

              label = inst.name.to_s
              if inst.classifier_name && !inst.classifier_name.empty?
                label = "#{label}: #{inst.classifier_name}"
              end
              HeaderLinePipeline.wrap_words(label, context, :bold).map do |line|
                [line, :bold]
              end
            end
          end
        end
      end
    end
  end
end
