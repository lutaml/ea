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
      # - the walk's position ordering (`sorted_by_position`), applied at
      #   the lookup for operation parameters so the UML tree and the
      #   extension block cannot disagree about their order. Attributes
      #   and operations are deliberately left for their callers to
      #   order — see `attributes_for`.
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

        # Whether a record can anchor a synthesized id. EA derives a
        # synthesized id's tail from its owner's GUID, so an owner
        # without one yields a tailless id. Both the UML tree and the
        # extension block ask this, so they cannot disagree about
        # whether to emit the thing that id would have named.
        # @param record [#ea_guid]
        # @return [Boolean]
        def identifiable?(record)
          !record&.ea_guid.to_s.strip.empty?
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

        # Deliberately NOT ordered here, unlike params_for_operation:
        # the extension block emits attributes in database order while
        # the LI-bound preallocation sorts them by name, so each caller
        # orders for itself. Sorting at this lookup would move export
        # bytes.
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

        # t_operationparams is loaded with an unordered SELECT, and both
        # the UML tree and the extension block emit parameters in Pos
        # order. Ordering here means no caller can obtain them unordered.
        # @param operation_id [Integer]
        # @return [Array<Ea::Qea::Models::EaOperationParam>]
        def params_for_operation(operation_id)
          sorted_by_position(database.operation_params_for(operation_id))
        end

        # ---- Ordering -----------------------------------------------------

        # EA emits a record's children in tree-position order (TPos / Pos),
        # ties broken by name.
        # @param records [Array<Ea::Qea::Models::BaseModel>]
        # @return [Array<Ea::Qea::Models::BaseModel>]
        def sorted_by_position(records)
          records.sort_by { |record| [record.sort_position, record.name.to_s] }
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