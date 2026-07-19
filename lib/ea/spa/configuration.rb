# frozen_string_literal: true

require "yaml"

module Ea
  module Spa
    # SPA-side configuration. A YAML file with the shape:
    #
    #   metadata:
    #     title: ...
    #     description: ...
    #     version: ...
    #     author: ...
    #     license: ...
    #     homepage: ...
    #     repository: ...
    #   ui:
    #     title: ...
    #     description: ...
    #
    # Values under `metadata` override fields on the model's
    # Ea::Model::Metadata. Values under `ui` (and other sections
    # like `appearance`) are surfaced to the SPA view via the
    # skeleton's metadata hash so the frontend can use them.
    class Configuration
      attr_reader :path, :data

      def self.load(path)
        return nil if path.nil? || path.empty?
        unless File.exist?(path)
          raise ArgumentError, "SPA config not found: #{path}"
        end

        new(path, YAML.safe_load(File.read(path)) || {})
      end

      def initialize(path, data)
        @path = path
        @data = data.is_a?(Hash) ? data : {}
      end

      def metadata_override
        (@data["metadata"] || {}).transform_keys(&:to_sym)
      end

      def ui
        @data["ui"] || {}
      end

      def appearance
        @data["appearance"] || {}
      end

      # Apply overrides to a model Metadata instance, returning a new
      # one. The original is left untouched.
      def apply_to_metadata(model_metadata)
        return model_metadata unless model_metadata

        merged = model_metadata_to_hash(model_metadata)
                                     .merge(stringify_keys(metadata_override))
        hash_to_metadata(merged)
      end

      # Surface the relevant config (ui, appearance) into a hash the
      # SPA skeleton embeds in its metadata payload.
      def view_extras
        { "ui" => ui, "appearance" => appearance }.reject { |_, v| v.nil? || v.empty? }
      end

      private

      def model_metadata_to_hash(meta)
        JSON.parse(meta.to_json)
      end

      def hash_to_metadata(hash)
        Ea::Model::Metadata.new(
          id: hash["id"] || "metadata",
          title: hash["title"],
          version: hash["version"],
          author: hash["author"],
          company: hash["company"],
          created_date: hash["createdDate"],
          modified_date: hash["modifiedDate"],
          source_format: hash["sourceFormat"],
          source_tool: hash["sourceTool"],
          source_path: hash["sourcePath"]
        )
      end

      def stringify_keys(hash)
        hash.transform_keys(&:to_s)
      end
    end
  end
end
