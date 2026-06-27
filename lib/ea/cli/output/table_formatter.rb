# frozen_string_literal: true

module Ea
  module Cli
    module Output
      class TableFormatter < Formatter
        COLUMN_WIDTH = 24
        SEPARATOR = "  "

        def render(rows, columns: [])
          return puts("(no rows)") if rows.empty?

          cols = columns.empty? ? Array(infer_columns(rows)) : columns
          puts render_header(cols)
          rows.each { |row| puts render_row(row, cols) }
        end

        private

        def render_header(cols)
          cols.map { |c| pad(c.to_s) }.join(SEPARATOR)
        end

        def render_row(row, cols)
          values =
            if row.is_a?(Hash)
              cols.map { |c| row[c] || row[c.to_s] }
            else
              row
            end
          values.map { |v| pad(v.to_s) }.join(SEPARATOR)
        end

        def pad(s)
          s.length >= COLUMN_WIDTH ? s : s.ljust(COLUMN_WIDTH)
        end
      end
    end
  end
end

Ea::Cli::Output.register(:table, Ea::Cli::Output::TableFormatter)
