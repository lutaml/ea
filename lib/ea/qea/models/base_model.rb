# frozen_string_literal: true

require "lutaml/model"

module Ea
  module Qea
    module Models
      class BaseModel < Lutaml::Model::Serializable
        def self.primary_key_column
          raise NotImplementedError,
                "#{self} must implement .primary_key_column"
        end

        def self.table_name
          raise NotImplementedError,
                "#{self} must implement .table_name"
        end

        def primary_key
          public_send(self.class.primary_key_column)
        end

        # Stable sort key used by transformers that need to emit children in
        # EA's tree-position order. Subclasses with a different field name
        # (e.g., `pos` on t_attribute rows) override this.
        # @return [Integer]
        def sort_position
          0
        end

        # Map of EA database column names to Ruby attribute names.
        # Subclasses override this for non-trivial mappings.
        # @return [Hash<String, Symbol>]
        def self.column_map
          {}
        end

        # Create instance from database row hash.
        # Uses column_map for explicit mappings, falls back to lowercase.
        # @param row [Hash] database row with string keys
        # @return [BaseModel, nil] new instance or nil
        def self.from_db_row(row)
          return nil if row.nil?

          mapping = column_map
          attrs = row.transform_keys do |key|
            if mapping.key?(key)
              mapping[key]
            else
              key.to_s.downcase.to_sym
            end
          end

          new(attrs)
        end
      end
    end
  end
end
