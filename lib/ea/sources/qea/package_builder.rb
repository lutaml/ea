# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Translates EA t_package rows into Ea::Model::Package
      # instances. References to parent and child packages are by
      # model id (normalized GUID), not by EA's integer Package_ID.
      class PackageBuilder
        attr_reader :database

        def initialize(database)
          @database = database
        end

        def build_all
          packages = database.collections[:packages] || []
          packages.map { |pkg| build_one(pkg) }
        end

        def build_one(pkg)
          Ea::Model::Package.new(
            id: IdNormalizer.from_guid(pkg.ea_guid),
            name: pkg.name,
            parent_id: parent_id_for(pkg),
            qualified_name: pkg.xmlpath,
            annotations: AnnotationBuilder.from_note(pkg.notes, pkg.ea_guid)
          )
        end

        private

        def parent_id_for(pkg)
          return nil if pkg.parent_id.nil? || pkg.parent_id.zero?

          parent = database.find_package(pkg.parent_id)
          return nil unless parent

          IdNormalizer.from_guid(parent.ea_guid)
        end
      end
    end
  end
end
