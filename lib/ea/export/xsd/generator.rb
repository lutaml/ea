# frozen_string_literal: true

require "nokogiri"

module Ea
  module Export
    module Xsd
      # Generates an XSD schema string from a parsed QEA model.
      #
      # Uses ClassMapping to translate UML class names to GML types
      # and NamespaceRegistry to declare target namespaces. Walks the
      # model's classifiers and emits `<xs:element>` + `<xs:complexType>`
      # pairs.
      #
      # Both class_mapping and namespaces default to the EA-bundled
      # GML fixtures when present, so callers can do
      #   Ea::Export::Xsd::Generator.call(model, target_namespace: ...)
      # without manually loading XML fixtures.
      class Generator
        XSD_NS = "http://www.w3.org/2001/XMLSchema"

        DEFAULT_MAPPING_PATH = "spec/fixtures/mdg/ea_config/gml/GMLClassMapping.xml".freeze
        DEFAULT_NAMESPACES_PATH = "spec/fixtures/mdg/ea_config/gml/GMLNamespaces.xml".freeze

        attr_reader :class_mapping, :namespaces

        def initialize(class_mapping: nil, namespaces: nil)
          @class_mapping = class_mapping || ClassMapping.from_path(DEFAULT_MAPPING_PATH)
          @namespaces = namespaces || NamespaceRegistry.from_path(DEFAULT_NAMESPACES_PATH)
        end

        # Class-method shortcut. Accepts the same options as #initialize
        # via keyword args.
        def self.call(model, target_namespace: "http://example.com/xsd",
                      prefix: "tns", **opts)
          new(**opts).call(model, target_namespace: target_namespace, prefix: prefix)
        end

        # Generate an XSD schema for the given model.
        # @param model [#collections] anything responding to #collections
        #   with a :packages and :objects collection (Ea::Qea::Database).
        # @param target_namespace [String] XSD targetNamespace
        # @param prefix [String] namespace prefix for the target
        # @return [String] serialized XSD
        def call(model, target_namespace:, prefix: "tns")
          doc = build_schema_doc(target_namespace, prefix)
          walk_model(model, doc)
          doc.to_xml(indent: 2)
        end

        private

        def build_schema_doc(target_namespace, prefix)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.schema("xmlns" => XSD_NS,
                       "xmlns:#{prefix}" => target_namespace,
                       "targetNamespace" => target_namespace,
                       "elementFormDefault" => "qualified")
          end
          builder.doc
        end

        def walk_model(model, doc)
          classes = model_classes(model)
          classes.each { |klass| emit_class(doc, doc.root, klass) }
        end

        # Extract UML-like classes from the model. Ea::Qea::Database
        # stores them in :objects; we filter to classes (Object_Type
        # == "Class") and emit a struct for the generator's needs.
        Classifier = Struct.new(:name, :stereotype, :attributes,
                                keyword_init: true)

        def model_classes(model)
          objects = model.collections[:objects] || []
          objects.select { |o| o.object_type == "Class" }.map do |obj|
            Classifier.new(
              name: obj.name,
              stereotype: stereotype_for(model, obj),
              attributes: attributes_for(model, obj)
            )
          end
        end

        def stereotype_for(model, obj)
          # Walk t_xref for the object's GUID; pick first @STEREO.
          xrefs = model.collections[:xrefs] || []
          stereo_xref = xrefs.find do |xr|
            xr.client == obj.ea_guid && xr.description&.include?("@STEREO")
          end
          return nil unless stereo_xref

          match = stereo_xref.description.match(/Name=([^;]+)/)
          match ? match[1] : nil
        end

        def attributes_for(model, obj)
          attrs = model.collections[:attributes] || []
          attrs.select { |a| a.object_id == obj.object_id }
               .map { |a| { name: a.name, type: a.type || "string" } }
        end

        def emit_class(doc, schema_root, classifier)
          mapping = class_mapping.for(classifier.name) ||
                    class_mapping.for(classifier.stereotype.to_s)

          type_name = mapping&.type || "#{classifier.name}Type"
          element_name = mapping&.element || classifier.name&.downcase

          schema_root.add_child(element_node(doc, element_name, type_name))
          schema_root.add_child(complex_type_node(doc, type_name, classifier))
        end

        def element_node(doc, name, type_name)
          el = doc.create_element("element", "xmlns" => XSD_NS)
          el["name"] = name
          el["type"] = "tns:#{type_name}"
          el
        end

        def complex_type_node(doc, type_name, classifier)
          ct = doc.create_element("complexType", "xmlns" => XSD_NS)
          ct["name"] = type_name
          seq = doc.create_element("sequence", "xmlns" => XSD_NS)
          classifier.attributes.each do |attr|
            seq.add_child(attribute_element(doc, attr))
          end
          ct.add_child(seq)
          ct
        end

        def attribute_element(doc, attr)
          el = doc.create_element("element", "xmlns" => XSD_NS)
          el["name"] = attr[:name].to_s
          el["type"] = "xs:string"
          el["minOccurs"] = "0"
          el
        end
      end
    end
  end
end
