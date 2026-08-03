# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # `ea diff OLD_FILE NEW_FILE`
      #
      # Standalone — does not require lutaml-uml. Loads two QEA databases
      # and reports added / removed / renamed entities.
      #
      # Exit code: 0 if identical, 1 if any differences found.
      class Diff < Base
        COLUMNS = %i[change kind id name].freeze

        def call
          if options[:format] == "html"
            write_html_report
          else
            rows = comparator.differences.map do |diff|
              [diff.change, diff.kind, diff.id, diff.name]
            end
            formatter.render(rows, columns: COLUMNS)
          end
          exit(1) if comparator.differences.any?
        end

        private

        def write_html_report
          html = Ea::Diff::HtmlReporter.new(comparator).render
          path = options[:output] || "diff_report.html"
          File.write(path, html)
          formatter.render([[path]], columns: [:written_to])
        end

        def comparator
          @comparator ||= begin
            old_db = load_database(options[:old])
            new_db = load_database(options[:new])
            Ea::Diff::Comparator.new(old_db, new_db)
          end
        end
      end
    end
  end
end
