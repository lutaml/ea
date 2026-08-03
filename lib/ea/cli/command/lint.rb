# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # `ea lint FILE [--rule=NAME] [--severity=error|warning]`
      #
      # Runs the Ea::Lint::Engine over a parsed model and reports
      # offenses. Exit 1 when errors are found.
      class Lint < Base
        COLUMNS = %i[severity rule entity_name message].freeze

        def call
          offenses = engine.run(model)
          offenses = filter_by_rule(offenses)
          offenses = filter_by_severity(offenses)
          rows = offenses.map { |o| [o.severity, o.rule, o.entity_name, o.message] }
          formatter.render(rows, columns: COLUMNS)
          exit(1) if offenses.any?(&:error?)
        end

        private

        def engine
          @engine ||= Ea::Lint::Engine.new
        end

        def model
          @model ||= load_database(file_path)
        end

        def filter_by_rule(offenses)
          return offenses unless options[:rule]

          rule_filter = options[:rule].to_s
          offenses.select { |o| o.rule.to_s.downcase.include?(rule_filter.downcase) }
        end

        def filter_by_severity(offenses)
          return offenses unless options[:severity]

          sev = options[:severity].to_sym
          offenses.select { |o| o.severity == sev }
        end
      end
    end
  end
end
