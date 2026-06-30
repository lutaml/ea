# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # `ea stats FILE`
      #
      # Standalone — does not require lutaml-uml. Reads the QEA database
      # directly and prints per-collection counts.
      class Stats < Base
        def call
          db = load_database
          stats = db.stats
          rows = stats.map { |k, v| [k, v] }
          formatter.render(rows, columns: %i[collection count])
        end
      end
    end
  end
end
