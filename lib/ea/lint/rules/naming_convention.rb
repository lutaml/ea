# frozen_string_literal: true

module Ea
  module Lint
    module Rules
      # Class names should be CamelCase. Attribute names should be
      # camelCase. Detect deviations.
      class NamingConventionRule < LintRule
        self.severity = :warning

        CLASS_PATTERN = /\A[A-Z][A-Za-z0-9]*\z/
        ATTR_PATTERN = /\A[a-z][A-Za-z0-9]*\z/

        def check(model)
          offenses = []
          classes = (model.collections[:objects] || [])
                     .select { |o| o.object_type == "Class" }
          classes.each do |klass|
            next if klass.name.nil? || klass.name.empty?

            unless klass.name.match?(CLASS_PATTERN)
              offenses << offense(entity_id: klass.object_id,
                                    entity_name: klass.name,
                                    message: "Class name is not CamelCase")
            end
          end

          attrs = model.collections[:attributes] || []
          attrs.each do |attr|
            next if attr.name.nil? || attr.name.empty?

            unless attr.name.match?(ATTR_PATTERN)
              offenses << offense(entity_id: attr.attribute_id || attr.object_id,
                                    entity_name: attr.name,
                                    message: "Attribute name is not camelCase")
            end
          end

          offenses
        end
      end
    end
  end
end
