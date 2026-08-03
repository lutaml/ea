# frozen_string_literal: true

require "json"

module Ea
  module Export
    module Json
      # Generates a JSON snapshot of a parsed QEA model.
      # Walks each collection and emits array entries with the row's
      # lutaml-model hash representation.
      class Generator
        def self.call(model, **_opts)
          new(model).call
        end

        attr_reader :model

        def initialize(model)
          @model = model
        end

        def call
          JSON.pretty_generate(document_hash)
        end

        private

        def document_hash
          model.collections.each_with_object({}) do |(name, records), acc|
            acc[name] = records.map { |r| record_hash(r) }
          end
        end

        def record_hash(record)
          hash = record.to_hash
          hash["record_type"] = record.class.name.split("::").last
          hash
        end
      end
    end
  end
end
