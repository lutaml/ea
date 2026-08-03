# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Translates EA t_object rows (filtered to classifier types)
      # into the appropriate Ea::Model::Classifier subclass. Uses
      # ObjectClassifierMap for dispatch (OCP — new classifier
      # kinds need no edit here).
      class ClassifierBuilder
        attr_reader :database, :mdg_registry

        def initialize(database, mdg_registry: nil)
          @database = database
          @mdg_registry = mdg_registry
        end

        def build_all
          classifiers = []
          each_classifier_object do |object|
            classifiers << build_one(object)
          end
          classifiers
        end

        def build_one(object)
          klass = classifier_class_for(object)
          args = common_args(object)
          args.merge!(enumeration_args(object)) if klass == Ea::Model::Enumeration
          args.delete(:properties) if klass == Ea::Model::Enumeration
          klass.new(**args)
        end

        # EA's `t_object.Object_Type` selects the concrete classifier
        # subclass, but a Class with the "enumeration" stereotype is
        # rendered as an Enumeration (literals compartment, no
        # visibility marker). Promote the model class when the
        # stereotype says so.
        def classifier_class_for(object)
          base = ObjectClassifierMap.class_for(object.object_type)
          return base unless base == Ea::Model::Klass
          return Ea::Model::Enumeration if enumeration_stereotype?(object)

          base
        end

        def enumeration_stereotype?(object)
          stereotype = object.stereotype.to_s
          !stereotype.empty? && stereotype.downcase == "enumeration"
        end

        # Resolves the classifier's full attribute list. Combines:
        #   1. Own properties from t_attribute
        #   2. Inherited properties from MDG-defined ancestor classes,
        #      when an mdg_registry is provided AND the classifier's
        #      applied stereotype maps to an MDG class.
        #
        # Public so integration tests can drive the merge directly
        # without stubbing the entire build_one pipeline.
        #
        # When no mdg_registry is wired in, this returns just the
        # own properties — preserving prior behavior.
        def properties_for(object)
          own = PropertyBuilder.new(database).build_all_for(object)
          return own unless mdg_registry

          inherited = mdg_inherited_properties_for(object)
          return own if inherited.empty?

          own_names = own.to_set { |p| p.name.to_s }
          own + inherited.reject { |p| own_names.include?(p.name.to_s) }
        end

        private

        def each_classifier_object
          objects = database.collections[:objects] || []
          objects.each do |obj|
            next unless classifier_type?(obj.object_type)

            yield obj
          end
        end

        def classifier_type?(object_type)
          ObjectClassifierMap::LOOKUP.key?(object_type)
        end

        def common_args(object)
          {
            id: IdNormalizer.from_guid(object.ea_guid),
            name: object.name,
            package_id: package_id_for(object),
            package_name: package_name_for(object),
            qualified_name: qualified_name_for(object),
            is_abstract: abstract?(object),
            visibility: visibility_from_scope(object.scope),
            properties: properties_for(object),
            operations: OperationBuilder.new(database).build_all_for(object),
            stereotype_refs: stereotype_refs_for(object),
            tagged_values: TaggedValueBuilder.new(database)
                                              .for_object(object.ea_guid,
                                                          ea_object_id: object.ea_object_id),
            constraints: constraints_for(object),
            annotations: AnnotationBuilder.from_note(object.note, object.ea_guid,
                                                     kind: "documentation")
          }
        end

        # Looks up the classifier's applied stereotype's MDG class
        # via the registry and returns its inherited properties.
        # Returns [] when no stereotype or no matching MDG class.
        def mdg_inherited_properties_for(object)
          stereotype = stereotype_target_name(object)
          return [] if stereotype.nil? || stereotype.empty?

          classifier = mdg_registry.find_classifier_by_name(stereotype)
          return [] unless classifier

          mdg_registry.inherited_properties_for(classifier.id).map do |entry|
            build_property_from_mdg_entry(entry)
          end
        end

        # EA's stereotype field can carry either the simple name
        # ("Type") or the FQName ("GML::Type"). We extract the
        # class name from either form for MDG lookup.
        def stereotype_target_name(object)
          raw = object.stereotype.to_s
          return nil if raw.empty?

          # FQName format: "MDGName::ClassName" — take the part
          # after the last "::". EA stores the simple form more
          # often than the FQName.
          raw.split("::").last
        end

        # EA renders association SourceRole names as virtual
        # "property" attributes on the SOURCE classifier. When a
        # connector has SourceRole="lod1ImplicitRepresentation",
        # EA shows "+lod1ImplicitRepresentation" inside the source
        # element's attribute compartment with «property»
        # stereotype.
        def association_role_properties_for(object)
          connectors = database.collections[:connectors] || []
          connectors.filter_map do |conn|
            next nil unless conn.start_object_id == object.ea_object_id

            role = conn.sourcerole.to_s
            next nil if role.empty?

            build_assoc_property(conn, role, object)
          end
        end

        def build_assoc_property(conn, role, owner_object)
          target = database.find_object(conn.end_object_id) if conn.end_object_id&.to_i&.positive?
          Ea::Model::Property.new(
            id: IdNormalizer.from_guid(conn.ea_guid),
            name: role,
            owner_id: IdNormalizer.from_guid(owner_object.ea_guid),
            type_name: target&.name,
            qualified_name: "#{owner_object.name}::#{role}",
            multiplicity_lower: parse_cardinality(conn.sourcecard, :lower),
            multiplicity_upper: parse_cardinality(conn.sourcecard, :upper),
            visibility: "public",
            aggregation: "none",
            stereotype_refs: ["property"],
            tagged_values: [],
            annotations: []
          )
        end

        def parse_cardinality(card_str, bound)
          return nil if card_str.nil? || card_str.to_s.empty?

          s = card_str.to_s
          parts = s.split("..")
          val = bound == :lower ? parts.first : (parts.size > 1 ? parts.last : parts.first)
          val = val.to_s.strip
          return -1 if val == "*"

          Integer(val)
        rescue ArgumentError
          nil
        end

        def build_property_from_mdg_entry(entry)
          Ea::Model::Property.new(
            id: "mdg:#{entry.name}",
            name: entry.name,
            visibility: entry.visibility || "public",
            multiplicity_lower: entry.multiplicity_lower,
            multiplicity_upper: entry.multiplicity_upper
          )
        end

        def constraints_for(object)
          rows = database.constraints_for_object(object.ea_object_id) || []
          rows.map do |row|
            Ea::Model::Constraint.new(
              id: IdNormalizer.from_guid("{#{row.constraint_id}}"),
              name: row.constraint.to_s,
              kind: row.constraint_type.to_s,
              body: row.notes.to_s,
              status: row.status.to_s
            )
          end
        end

        def enumeration_args(object)
          literals = enumeration_literals_for(object)
          { literals: literals }
        end

        def enumeration_literals_for(object)
          # EA stores enum literals as attributes with no type, or as
          # child t_object rows tagged as Literal. We pick them up
          # from attributes where type is empty/nil and treat the
          # attribute name as the literal value.
          attrs = database.attributes_for_object(object.ea_object_id) || []
          attrs.map.with_index do |attr, idx|
            Ea::Model::EnumerationLiteral.new(
              id: IdNormalizer.from_guid(attr.ea_guid),
              name: attr.name,
              value: attr.default || attr.name,
              ordinal: idx
            )
          end
        end

        def package_id_for(object)
          pkg = database.find_package(object.package_id)
          return nil unless pkg

          IdNormalizer.from_guid(pkg.ea_guid)
        end

        def package_name_for(object)
          pkg = database.find_package(object.package_id)
          pkg&.name
        end

        # EA renders classifier names with a qualifier prefix using
        # "::" — package prefix for top-level classes, parent-class
        # prefix for nested classes. The QEA t_object.Name may
        # already include a ":" prefix (e.g. "gml:CodeType"); use
        # it verbatim.
        def qualified_name_for(object)
          name = object.name.to_s
          return name if name.include?(":")
          return name if name.empty?

          parent_name = nested_parent_name(object)
          return "#{parent_name}::#{name}" if parent_name

          pkg = database.find_package(object.package_id)
          pkg_name = pkg&.name
          pkg_name ? "#{pkg_name}::#{name}" : name
        end

        # When t_object.ParentID points at a Class (not a Package),
        # the object is a nested classifier. EA qualifies its name
        # with the parent class's name, not the package name.
        def nested_parent_name(object)
          parent_id_value = object.parentid
          return nil unless parent_id_value && parent_id_value.to_i.positive?

          parent = database.find_object(parent_id_value.to_i)
          return nil unless parent&.object_type == "Class"

          parent.name.to_s
        end

        def abstract?(object)
          %w[1 true].include?(object.abstract.to_s)
        end

        def visibility_from_scope(scope)
          case scope.to_s
          when "Public" then "public"
          when "Protected" then "protected"
          when "Private" then "private"
          else "public"
          end
        end

        def stereotype_refs_for(object)
          refs = []
          refs << object.stereotype if object.stereotype && !object.stereotype.empty?
          refs
        end
      end
    end
  end
end
