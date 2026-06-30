# frozen_string_literal: true

require "json"

module Ea
  module Cli
    module Output
      class JsonFormatter < Formatter
        def render(rows, columns: [])
          data = rows.map do |row|
            normalize_row(row, columns)
          end
          puts JSON.pretty_generate(data)
        end
      end
    end
  end
end

Ea::Cli::Output.register(:json, Ea::Cli::Output::JsonFormatter)
