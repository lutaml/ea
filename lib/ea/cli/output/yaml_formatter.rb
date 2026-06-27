# frozen_string_literal: true

require "yaml"

module Ea
  module Cli
    module Output
      class YamlFormatter < Formatter
        def render(rows, columns: [])
          data = rows.map do |row|
            normalize_row(row, columns)
          end
          puts data.to_yaml
        end
      end
    end
  end
end

Ea::Cli::Output.register(:yaml, Ea::Cli::Output::YamlFormatter)
