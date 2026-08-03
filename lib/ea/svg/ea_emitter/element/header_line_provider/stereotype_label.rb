# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        module HeaderLineProvider
          # Emits the stereotype label `«name»` for classifiers with
          # an explicit stereotype, OR a type-derived fallback
          # («enumeration», «dataType», etc.) for non-Klass classifiers.
          #
          # Plain Klass with no stereotype gets no label — EA's
          # behavior.
          #
          # InstanceSpecification is excluded (it owns its own header).
          class StereotypeLabel
            def self.call(context)
              classifier = context.classifier
              return [] if classifier.is_a?(Ea::Model::InstanceSpecification)

              label = label_for(classifier, context.umldi_keyword)
              return [] unless label

              [[label, :normal]]
            end

            # @return [String, nil] «name» label or nil
            def self.label_for(classifier, umldi_keyword)
              return "«#{umldi_keyword}»" if umldi_keyword && !umldi_keyword.empty?

              explicit = explicit_stereotype(classifier)
              return explicit if explicit

              case classifier
              when Ea::Model::Klass, Ea::Model::Package, Ea::Model::Note
                nil
              else
                fallback = fallback_name(classifier)
                fallback ? "«#{fallback}»" : nil
              end
            end

            def self.explicit_stereotype(classifier)
              return nil unless classifier.is_a?(Ea::Model::Classifier) ||
                                 classifier.is_a?(Ea::Model::Package)

              refs = classifier.stereotype_refs
              return nil unless refs&.any?

              "«#{refs.first}»"
            end

            def self.fallback_name(classifier)
              case classifier
              when Ea::Model::Enumeration then "enumeration"
              when Ea::Model::DataType then "dataType"
              when Ea::Model::PrimitiveType then "primitive"
              when Ea::Model::Interface then "interface"
              when Ea::Model::Signal then "signal"
              else "DataType"
              end
            end
          end
        end
      end
    end
  end
end
