# frozen_string_literal: true

require "json"

module Ea
  module Export
    module Json
      # Generates a curated JSON snapshot of a parsed QEA model.
      #
      # Each collection is projected through a per-model schema so the
      # output is stable and free of Lutaml::Model internals.
      # Collections without a projection are emitted as
      # `{ "name" => ..., "id" => ..., "record_type" => ... }` triples
      # — enough metadata for downstream tools without leaking
      # implementation details.
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
          {
            "schema_version" => "1.0",
            "collections" => projected_collections
          }
        end

        def projected_collections
          model.collections.each_with_object({}) do |(name, records), acc|
            acc[name.to_s] = records.map { |r| project(r) }
          end
        end

        # @return [Hash] curated fields per record type
        def project(record)
          projector = PROJECTORS[record.class]
          return projector.call(record) if projector

          default_projection(record)
        end

        # Fallback: name + id + record_type only
        def default_projection(record)
          {
            "id" => safe_id(record),
            "name" => record_name(record),
            "record_type" => record.class.name.split("::").last
          }
        end

        def safe_id(record)
          return nil unless record.is_a?(Ea::Qea::Models::BaseModel)

          pk = record.class.primary_key_column
          return nil if pk.nil?

          record.to_hash[pk.to_s] || record.to_hash[pk.to_sym]
        end

        def record_name(record)
          record.to_hash["name"] || record.to_hash[:name]
        end

        # Per-class projections: each entry is a proc returning a Hash.
        # Add new entries here as we curate more model types.
        PROJECTORS = {
          Ea::Qea::Models::EaObject => ->(r) do
            {
              "id" => r.ea_object_id, "name" => r.name,
              "type" => r.object_type, "author" => r.author,
              "package_id" => r.package_id, "version" => r.version
            }
          end,
          Ea::Qea::Models::EaAttribute => ->(r) do
            {
              "id" => r.id, "name" => r.name,
              "type" => r.type, "object_id" => r.ea_object_id,
              "visibility" => r.scope
            }
          end,
          Ea::Qea::Models::EaPackage => ->(r) do
            {
              "id" => r.package_id, "name" => r.name,
              "parent_id" => r.parent_id
            }
          end,
          Ea::Qea::Models::EaConnector => ->(r) do
            {
              "id" => r.connector_id, "name" => r.name,
              "type" => r.connector_type,
              "start_object_id" => r.start_object_id,
              "end_object_id" => r.end_object_id
            }
          end,
          Ea::Qea::Models::EaDiagram => ->(r) do
            {
              "id" => r.diagram_id, "name" => r.name,
              "type" => r.diagram_type, "package_id" => r.package_id
            }
          end
        }.freeze
      end
    end
  end
end
