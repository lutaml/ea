# frozen_string_literal: true

module Ea
  module Lint
    module Rules
      # Class with no parent package (orphan). Usually indicates a
      # modeling accident.
      class OrphanElementRule < LintRule
        self.severity = :warning

        def check(model)
          valid_pkg_ids = (model.collections[:packages] || [])
                            .map(&:package_id).to_set

          (model.collections[:objects] || []).select { |o| o.object_type == "Class" }.map do |klass|
            next unless klass.package_id

            unless valid_pkg_ids.include?(klass.package_id)
              offense(entity_id: klass.object_id,
                      entity_name: klass.name,
                      message: "Class references missing package_id=#{klass.package_id}")
            end
          end.compact
        end
      end
    end
  end
end
