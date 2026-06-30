# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Shared state passed across the walk.
      #
      # Wraps the {Ea::Qea::Database} and provides:
      # - ID-derivation helpers (`xmi_id_for`, `end_xmi_id_for`) backed by
      #   {GuidFormat}
      # - delegated database lookups (objects, packages, attributes, etc.)
      #
      # The {Ea::Qea::Database} already maintains its own lookup indexes
      # (object-by-id, connectors-by-object, attributes-by-object, etc.).
      # This class delegates to those rather than re-indexing — single source
      # of truth lives on the database.
      class Context
        attr_reader :database, :id_allocator

        def initialize(database:)
          @database = database
          @id_allocator = IdAllocator.new
        end

        # ---- ID helpers ---------------------------------------------------

        # @param record [#ea_guid]
        # @param prefix [String] "EAID" (default) or "EAPK" for top-level packages
        # @return [String, nil]
        def xmi_id_for(record, prefix: "EAID")
          return nil unless record&.ea_guid

          GuidFormat.ea_guid_to_xmi_id(record.ea_guid, prefix: prefix)
        end

        # @param connector_xmi_id [String]
        # @param side [Symbol] :source or :destination
        # @return [String]
        def end_xmi_id_for(connector_xmi_id, side:)
          GuidFormat.connector_end_xmi_id(connector_xmi_id, side: side)
        end

        # ---- Database lookups --------------------------------------------

        # @param ea_guid [String]
        # @return [Ea::Qea::Models::EaObject, nil]
        def object_by_guid(ea_guid)
          database.find_object_by_guid(ea_guid)
        end

        # @param object_id [Integer]
        # @return [Ea::Qea::Models::EaObject, nil]
        def object_by_id(object_id)
          database.find_object(object_id)
        end

        # @param package_id [Integer]
        # @return [Array<Ea::Qea::Models::EaPackage>]
        def child_packages(package_id)
          database.child_packages_for(package_id)
        end

        # @param package_id [Integer]
        # @return [Array<Ea::Qea::Models::EaObject>]
        def objects_in_package(package_id)
          database.objects_in_package(package_id)
        end

        # @param object_id [Integer]
        # @return [Array<Ea::Qea::Models::EaAttribute>]
        def attributes_for(object_id)
          database.attributes_for_object(object_id)
        end

        # @param object_id [Integer]
        # @return [Array<Ea::Qea::Models::EaOperation>]
        def operations_for(object_id)
          database.operations_for_object(object_id)
        end

        # @param operation_id [Integer]
        # @return [Array<Ea::Qea::Models::EaOperationParam>]
        def params_for_operation(operation_id)
          database.operation_params_for(operation_id)
        end

        # Connectors where the object is on either side.
        # @param object_id [Integer]
        # @return [Array<Ea::Qea::Models::EaConnector>]
        def connectors_for(object_id)
          database.connectors_for_object(object_id)
        end

        # Connectors where this object is the start (source) — used to decide
        # which package owns a relationship connector.
        # @param object_id [Integer]
        # @return [Array<Ea::Qea::Models::EaConnector>]
        def connectors_starting_at(object_id)
          database.connectors_for_object(object_id).select do |conn|
            conn.start_object_id == object_id
          end
        end
      end
    end
  end
end