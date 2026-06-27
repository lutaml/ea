# frozen_string_literal: true

module Ea
  module Qea
    module Infrastructure
      autoload :DatabaseConnection,
               "ea/qea/infrastructure/database_connection"
      autoload :SchemaReader, "ea/qea/infrastructure/schema_reader"
      autoload :TableReader, "ea/qea/infrastructure/table_reader"
    end
  end
end
