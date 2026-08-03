# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Predicate: should this element be rendered, or is it a
        # diagram-frame placeholder that EA skips?
        class Filter
          attr_reader :model_index

          def initialize(model_index:)
            @model_index = model_index
          end

          # Returns true if the element should be SKIPPED.
          # EA emits a "diagram frame placeholder" Classifier with
          # no name and no properties on some diagrams — those get
          # dropped. Packages and named Classifiers are always kept.
          def skip?(element)
            return false unless element.background_color == -1

            classifier = classifier_for(element)
            return false unless classifier

            classifier.name.to_s.strip.empty? && (classifier.properties.nil? || classifier.properties.empty?)
          end

          private

          def classifier_for(element)
            ref = element.model_element_ref
            return nil unless ref

            candidate = model_index[ref]
            return nil unless candidate.is_a?(Ea::Model::Classifier)

            candidate
          end
        end
      end
    end
  end
end
