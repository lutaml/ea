# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        module HeaderLineProvider
          # InstanceSpecification: short-circuits the pipeline. The
          # header for an instance is its own «stereotype» line (the
          # t_object.Stereotype value, verbatim - «featureType»,
          # «FeatureType», «type» …) followed by "name: Classifier"
          # on one bold line, word-wrapped when it overflows the box
          # (81F92FC7: "new ownership:" / "LA_Right"). The stereotype
          # line is suppressed by the diagram pdata flag
          # HideEStereo=1 (FC590D99 shows it; the Annex C "Case"
          # diagrams with HideEStereo=1 show none).
          class InstanceSpec
            def self.call(context)
              inst = context.classifier
              return [] unless inst.is_a?(Ea::Model::InstanceSpecification)

              lines = stereotype_lines(inst, context)
              lines + HeaderLinePipeline.wrap_words(label_for(inst), context, :bold).map do |line|
                [line, :bold]
              end
            end

            # "Name / alias: Classifier"; t_object.Alias is the instance role.
            def self.label_for(inst)
              label = inst.name.to_s
              label = "#{label} / #{inst.role_name}" unless inst.role_name.to_s.empty?
              return label if inst.classifier_name.to_s.empty?

              "#{label}: #{inst.classifier_name}"
            end

            def self.stereotype_lines(inst, context)
              return [] if context.suppress_stereotypes

              st = inst.stereotype.to_s
              return [] if st.empty?

              [["«#{st}»", :normal]]
            end
          end
        end
      end
    end
  end
end
