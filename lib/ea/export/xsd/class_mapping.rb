# frozen_string_literal: true

require "nokogiri"

module Ea
  module Export
    module Xsd
      # Loads EA's GMLClassMapping.xml and exposes per-class mapping
      # rules: UML class name → GML element/type/propertyType names.
      #
      # XML format:
      #   <ClassMapping>
      #     <Class name="FeatureType" element="featureMember"
      #           type="FeaturePropertyType" propertyType="..."
      #           typeContent="complex"/>
      #   </ClassMapping>
      class ClassMapping
        attr_reader :mappings

        # @param mappings [Hash{String => Mapping}] keyed by UML class name
        def initialize(mappings = {})
          @mappings = mappings
        end

        Mapping = Struct.new(:name, :element, :type, :property_type,
                             :type_content, keyword_init: true)

        # @param path [String] path to GMLClassMapping.xml
        # @return [ClassMapping]
        def self.from_path(path)
          return new if path.nil? || !File.exist?(path)

          from_nokogiri(Nokogiri::XML(File.read(path)))
        end

        # @param doc [Nokogiri::XML::Document]
        # @return [ClassMapping]
        def self.from_nokogiri(doc)
          mappings = {}
          doc.xpath("//Class").each do |node|
            name = node["name"]
            next unless name

            mappings[name] = Mapping.new(
              name: name,
              element: node["element"],
              type: node["type"],
              property_type: node["propertyType"],
              type_content: node["typeContent"]
            )
          end
          new(mappings)
        end

        # Look up a mapping by UML class name. Returns nil when no
        # explicit mapping exists.
        # @param class_name [String]
        # @return [Mapping, nil]
        def for(class_name)
          mappings[class_name]
        end
      end
    end
  end
end
