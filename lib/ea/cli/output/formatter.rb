# frozen_string_literal: true

module Ea
  module Cli
    module Output
      class Formatter
        def render(rows, columns: [])
          raise NotImplementedError
        end

        protected

        def normalize_row(row, columns)
          return row if row.is_a?(Hash)

          columns.each_with_index.to_h { |k, i| [k, row[i]] }
        end

        def infer_columns(rows)
          first = rows.first
          return columns_of(first) if first

          []
        end

        private

        def columns_of(obj)
          obj.is_a?(Hash) ? obj.keys.map(&:to_sym) : []
        end
      end
    end
  end
end
