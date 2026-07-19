# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Builds an Ea::Model::Metadata from the QEA database. Pulls
      # project-level info (model name, version, tool, source path)
      # from the root package and the QEA file path.
      class MetadataBuilder
        attr_reader :database, :qea_path

        def initialize(database, qea_path)
          @database = database
          @qea_path = qea_path
        end

        def build
          root_pkg = root_package
          Ea::Model::Metadata.new(
            id: "metadata",
            title: root_pkg&.name,
            version: root_pkg&.version,
            created_date: root_pkg&.createddate,
            modified_date: root_pkg&.modifieddate,
            author: root_pkg&.pkgowner,
            source_format: "qea",
            source_tool: "Sparx Enterprise Architect",
            source_path: qea_path
          )
        end

        private

        def root_package
          @root_package ||= database.collections[:packages]&.find do |pkg|
            pkg.parent_id.nil? || pkg.parent_id.zero?
          end
        end
      end
    end
  end
end
