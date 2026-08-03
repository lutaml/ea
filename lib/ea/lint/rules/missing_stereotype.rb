# frozen_string_literal: true

module Ea
  module Lint
    module Rules
      # Flags classes with no applied stereotype. Stereotype
      # detection walks t_xref for `@STEREO;Name=...;` blocks
      # referencing the class's ea_guid.
      class MissingStereotypeRule < LintRule
        self.severity = :info

        def check(model)
          classes = (model.collections[:objects] || [])
                     .select { |o| o.object_type == "Class" }
          xrefs = model.collections[:xrefs] || []
          classes.map do |klass|
            next nil if stereotype_name_for(klass, xrefs)

            offense(entity_id: klass.object_id,
                    entity_name: klass.name,
                    message: "Class has no applied stereotype",
                    severity: :info)
          end.compact
        end

        private

        # Find the first @STEREO application in t_xref that references
        # the class's ea_guid.
        def stereotype_name_for(klass, xrefs)
          return nil unless klass.is_a?(Ea::Qea::Models::EaObject)

          xrefs.find do |xr|
            xr.client == klass.ea_guid && xr.description&.include?("@STEREO")
          end&.description&.match(/Name=([^;]+)/)&.[](1)
        end
      end
    end
  end
end
