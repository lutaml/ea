# frozen_string_literal: true

module Ea
  module Lint
    module Rules
      # Packages named "Application Schema" or with `applicationSchema`
      # stereotype should have at least one class with a GML stereotype.
      class MissingStereotypeRule < LintRule
        self.severity = :info

        GML_STEREOTYPES = %w[FeatureType Type DataType CodeList
                             Enumeration ObjectType].freeze

        def check(model)
          classes = (model.collections[:objects] || [])
                     .select { |o| o.object_type == "Class" }
          classes_without_stereo = classes.select { |c| stereotype_refs(c).empty? }
          classes_without_stereo.map do |klass|
            offense(entity_id: klass.object_id,
                    entity_name: klass.name,
                    message: "Class has no applied stereotype",
                    severity: :info)
          end
        end

        private

        def stereotype_refs(klass)
          refs = klass.respond_to?(:stereotype_refs) ? klass.stereotype_refs : nil
          refs || []
        end
      end
    end
  end
end
