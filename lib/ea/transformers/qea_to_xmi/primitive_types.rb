# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Owns the `EAnone_` id shape and EA's <primitivetypes> Extension
      # hierarchy: every distinct attribute/operation type name with a
      # blank classifier becomes an `EAnone_<name>` PrimitiveType
      # definition, in table first-use order (attributes then operations
      # — verified to match the reference exports' ordering).
      #
      # `definition_id` is also what the transformer's type REFERENCES
      # go through, so a reference and its definition normalize the name
      # identically and cannot end up as two different ids.
      #
      # Names EA maps to OMG standard primitives are excluded on the
      # attribute side only, and only when the classifier is blank, since
      # that is the sole case where the attribute carries an href child
      # instead of an idref.
      #
      # KNOWN GAP: a non-blank classifier that resolves to nothing (a
      # numeric t_object id from a referenced model) still emits an
      # `EAnone_` reference with no definition behind it. Defining those
      # here over-emits instead: this scan walks every row in the
      # database, including rows the package walk never exports, and EA's
      # own plateau export defines nothing for them. Closing it means
      # deriving definitions from the references the walk actually
      # emitted, which is its own change.
      module PrimitiveTypes
        # EA primitive names that reference the OMG PrimitiveTypes
        # library instead of a synthesized EAnone_ definition.
        HREF_NAMES = { "int" => "Integer" }.freeze

        OMG_PRIMITIVES = "http://www.omg.org/spec/UML/20110701/PrimitiveTypes.xmi"

        module_function

        # @param database [Ea::Qea::Database]
        # @return [Array<String>] distinct unresolved type names, first-use order
        def unresolved_names(database)
          (attribute_names(database) + operation_names(database)).uniq
        end

        # An attribute reaches the OMG library through an href child only
        # when it has no classifier to point at. One that names a
        # classifier resolves against it instead, so it needs no
        # definition here — see the KNOWN GAP above for the case where
        # that classifier resolves to nothing.
        def attribute_names(database)
          database.attributes.filter_map do |attr|
            next nil if href_for(attr.type, attr.classifier)

            unresolved_name(attr.type, attr.classifier)
          end
        end

        # Operation returns have no href mechanism — they reference
        # EAnone_<name> directly, so every name they use must be
        # defined here or the idref dangles.
        def operation_names(database)
          database.operations.filter_map { |op| unresolved_name(op.type, op.classifier) }
        end

        def unresolved_name(type, classifier)
          name = normalize_name(type)
          return nil if name.empty?
          return nil unless blank_classifier?(classifier)

          name
        end

        # The id EA gives a type name that has no classifier behind it.
        # The reference and the definition both come from here, so they
        # cannot normalize the name differently.
        # @return [String] e.g. "EAnone_int"
        def definition_id(type_name)
          "EAnone_#{normalize_name(type_name)}"
        end

        # EA type columns are free text; leading/trailing space is not
        # part of the name.
        def normalize_name(type)
          type.to_s.strip
        end

        # The OMG href replaces the EAnone_ idref only when there is no
        # classifier to point at. Nil means "not an href target", so the
        # definition side and the transformer read one expression rather
        # than asking a predicate and then fetching what it proved.
        # @return [String, nil] OMG href for EA primitive names, else nil
        def href_for(type, classifier)
          return nil unless blank_classifier?(classifier)

          target = HREF_NAMES[normalize_name(type)]
          target && "#{OMG_PRIMITIVES}##{target}"
        end

        def blank_classifier?(classifier)
          text = normalize_name(classifier)
          text.empty? || text == "0"
        end
      end
    end
  end
end
