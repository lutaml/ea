# frozen_string_literal: true

module Ea
  module Qea
    module Factory
      # Abstract base class for all EA to UML transformers
      # Implements the Strategy pattern for model transformation
      class BaseTransformer
        attr_reader :database

        # Initialize transformer with database reference
        # @param database [Ea::Qea::Database] QEA database instance
        def initialize(database)
          @database = database
        end

        # Transform a single EA model to UML model
        # @param ea_model [BaseModel] EA model instance
        # @return [Object] UML model instance
        # @raise [NotImplementedError] Must be implemented by subclasses
        def transform(ea_model)
          raise NotImplementedError,
                "#{self.class} must implement #transform"
        end

        # Transform a collection of EA models to UML models
        # @param collection [Array<BaseModel>] Collection of EA models
        # @return [Array<Object>] Collection of UML models
        def transform_collection(collection)
          return [] if collection.nil? || collection.empty?

          collection.filter_map { |item| transform(item) }
        end

        # Map EA visibility to UML visibility
        # @param ea_visibility [String] EA visibility value
        # @return [String] UML visibility value
        def map_visibility(ea_visibility) # rubocop:disable Metrics/CyclomaticComplexity
          return "public" if ea_visibility.nil? || ea_visibility.empty?

          case ea_visibility.downcase
          when "private" then "private"
          when "protected" then "protected"
          when "package" then "package"
          else "public"
          end
        end

        # Parse cardinality string to min/max values
        # @param cardinality_str [String] Cardinality string (e.g., "0..1",
        #   "1..*")
        # @return [Hash] Hash with :min and :max keys
        def parse_cardinality(cardinality_str)
          return { min: nil, max: nil } if cardinality_str.nil? ||
            cardinality_str.empty?

          parts = cardinality_str.split("..")
          if parts.size == 2
            { min: parts[0], max: parts[1] }
          elsif parts.size == 1
            { min: parts[0], max: parts[0] }
          else
            { min: nil, max: nil }
          end
        end

        # Convert boolean-like values to actual boolean
        # @param value [Object] Value to convert
        # @return [Boolean] Boolean value
        def to_boolean(value)
          return false if value.nil?
          return value if [true, false].include?(value)

          value.to_s == "1" || value.to_s.downcase == "true"
        end

        # Normalize EA GUID to XMI ID format
        # Converts {GUID-WITH-HYPHENS} to PREFIX_GUID_WITH_UNDERSCORES
        # @param ea_guid [String] EA GUID in format
        # "{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}"
        # @param prefix [String] Prefix to add (e.g., "EAID", "EAPK")
        # @return [String, nil] XMI ID in format
        # "PREFIX_XXXXXXXX_XXXX_XXXX_XXXX_XXXXXXXXXXXX"
        def normalize_guid_to_xmi_format(ea_guid, prefix = "EAID")
          return nil if ea_guid.nil? || ea_guid.empty?

          # Remove braces and replace hyphens with underscores
          clean = ea_guid.tr("{}", "").tr("-", "_")
          "#{prefix}_#{clean}"
        end

        # Convert ea_guid to XMI SRC ID format
        def normalize_guid_to_xmi_src_dst_format(
          ea_guid, prefix = "EAID", is_src = true # rubocop:disable Style/OptionalBooleanParameter
        )
          xmi_id = normalize_guid_to_xmi_format(ea_guid, prefix)

          # Trim prefix and add _src or _dst
          src_dst = is_src ? "src" : "dst"
          clean = xmi_id[(prefix.length + 3), xmi_id.length]
          "#{prefix}_#{src_dst}#{clean}"
        end

        # Normalize line endings from Windows (\r\n) to Unix (\n)
        # EA database stores text with Windows line endings, but XMI uses Unix
        # @param text [String, nil] Text to normalize
        # @return [String, nil] Text with normalized line endings
        def normalize_line_endings(text)
          return nil if text.nil?

          text.gsub("\r\n", "\n")
        end

        # Find object by ID
        # @param object_id [Integer] Object ID
        # @return [Models::EaObject, nil] EA object or nil
        def find_object_by_id(object_id)
          return nil if object_id.nil?

          database.find_object(object_id)
        end

        # Load and transform tagged values for an element
        # @param ea_guid [String] Element GUID
        # @return [Array<Lutaml::Uml::TaggedValue>] UML tagged values
        def load_tagged_values(ea_guid)
          return [] if ea_guid.nil?

          ea_tags = database.tagged_values_for_element(ea_guid)
          TaggedValueTransformer.new(database).transform_collection(ea_tags)
        end

        # Load and transform attributes for an object
        # @param object_id [Integer] Object ID
        # @return [Array<Lutaml::Uml::TopElementAttribute>] UML attributes
        def load_attributes(object_id)
          return [] if object_id.nil?

          ea_attributes = database.attributes_for_object(object_id)
            .sort_by { |a| a.pos || 0 }
          AttributeTransformer.new(database).transform_collection(ea_attributes)
        end

        # Load and transform operations for an object
        # @param object_id [Integer] Object ID
        # @return [Array<Lutaml::Uml::Operation>] UML operations
        def load_operations(object_id)
          return [] if object_id.nil?

          ea_operations = database.operations_for_object(object_id)
            .sort_by { |op| op.pos || 0 }
          OperationTransformer.new(database).transform_collection(ea_operations)
        end

        # Load and transform constraints for an object
        # @param object_id [Integer] Object ID
        # @return [Array<Lutaml::Uml::Constraint>] UML constraints
        def load_constraints(object_id)
          return [] if object_id.nil?

          ea_constraints = database.constraints_for_object(object_id)
          ConstraintTransformer.new(database).transform_collection(ea_constraints)
        end

        # Load and transform object properties for an object
        # @param object_id [Integer] Object ID
        # @return [Array<Lutaml::Uml::TaggedValue>] UML tagged values
        def load_object_properties(object_id)
          return [] if object_id.nil?

          ea_props = database.properties_for_object(object_id)
          ObjectPropertyTransformer.new(database).transform_collection(ea_props)
        end
      end
    end
  end
end
