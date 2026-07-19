# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      class MetadataBuilder
        attr_reader :root, :xmi_path

        def initialize(root, xmi_path)
          @root = root
          @xmi_path = xmi_path
        end

        def build
          model = root.model
          documentation = root.documentation
          Ea::Model::Metadata.new(
            id: "metadata",
            title: model&.name,
            version: documentation&.exporter_version,
            author: documentation&.exporter,
            created_date: nil,
            modified_date: documentation&.timestamp&.first&.iso8601,
            source_format: "xmi",
            source_tool: documentation&.exporter,
            source_path: xmi_path
          )
        end
      end
    end
  end
end
