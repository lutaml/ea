# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Synthesizes EA's <primitivetypes> Extension hierarchy: every
      # distinct attribute/operation type name with a blank classifier
      # becomes an `EAnone_<name>` PrimitiveType definition, in table
      # first-use order (attributes then operations — verified to match
      # the reference exports' ordering). Names EA maps to OMG standard
      # primitives (via href) are excluded.
      module PrimitiveTypes
        # EA primitive names that reference the OMG PrimitiveTypes
        # library instead of a synthesized EAnone_ definition.
        HREF_NAMES = { "int" => "Integer" }.freeze

        OMG_PRIMITIVES = "http://www.omg.org/spec/UML/20110701/PrimitiveTypes.xmi"

        module_function

        # @param database [Ea::Qea::Database]
        # @return [Array<String>] distinct unresolved type names, first-use order
        def unresolved_names(database)
          (database.attributes.map { |a| unresolved_name(a.type, a.classifier) } +
           database.operations.map { |o| unresolved_name(o.type, o.classifier) })
            .compact.uniq
        end

        def unresolved_name(type, classifier)
          name = type.to_s.strip
          return nil if name.empty? || HREF_NAMES.key?(name)
          return nil unless blank_classifier?(classifier)

          name
        end

        # @return [String, nil] OMG href for EA primitive names, else nil
        def href_for(type)
          target = HREF_NAMES[type.to_s.strip]
          target && "#{OMG_PRIMITIVES}##{target}"
        end

        def blank_classifier?(classifier)
          text = classifier.to_s.strip
          text.empty? || text == "0"
        end
      end
    end
  end
end
