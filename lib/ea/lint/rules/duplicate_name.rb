# frozen_string_literal: true

module Ea
  module Lint
    module Rules
      # Two classes with the same name in the same package.
      class DuplicateNameRule < LintRule
        self.severity = :warning

        def check(model)
          classes = (model.collections[:objects] || [])
                     .select { |o| o.object_type == "Class" }
          grouped = classes.group_by { |c| [c.package_id, c.name] }
          grouped.flat_map do |(pkg_id, name), group|
            next [] if group.size == 1

            group.map do |klass|
              offense(entity_id: klass.object_id,
                      entity_name: klass.name,
                      message: "Duplicate class name '#{name}' in package #{pkg_id} " \
                               "(#{group.size} occurrences)")
            end
          end
        end
      end
    end
  end
end
