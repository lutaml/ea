# frozen_string_literal: true

require "nokogiri"

module Ea
  module Export
    module Xsd
      # Loads EA's GMLNamespaces.xml and exposes per-prefix namespace
      # declarations: prefix → { target_namespace:, xsd_document: }.
      #
      # XML format:
      #   <Namespaces>
      #     <GMLNS version="3.2.1">
      #       <Namespace xmlns="gml" targetNamespace="http://..."
      #                  xsdDocument="http://.../gml.xsd"/>
      #     </GMLNS>
      #   </Namespaces>
      class NamespaceRegistry
        attr_reader :namespaces

        # @param namespaces [Hash{String => Namespace}]
        def initialize(namespaces = {})
          @namespaces = namespaces
        end

        Namespace = Struct.new(:prefix, :target_namespace, :xsd_document,
                               :version, keyword_init: true)

        # @param path [String] path to GMLNamespaces.xml
        # @param version [String, nil] GML version filter (e.g. "3.2.1")
        # @return [NamespaceRegistry]
        def self.from_path(path, version: nil)
          return new if path.nil? || !File.exist?(path)

          from_nokogiri(Nokogiri::XML(File.read(path)), version: version)
        end

        # @param doc [Nokogiri::XML::Document]
        # @param version [String, nil] GML version filter
        # @return [NamespaceRegistry]
        def self.from_nokogiri(doc, version: nil)
          namespaces = {}
          # EA stores the prefix in a `xmlns` attribute, which XML
          # reserves for namespace declarations. Nokogiri interprets
          # it as the element's namespace, so we read it back via
          # `namespace` (the parsed NS) rather than `attribute`.
          # Use local-name() so the lookup is namespace-agnostic.
          doc.xpath("//*[local-name()='GMLNS']").each do |gmlns|
            next if version && gmlns["version"] != version

            gmlns.element_children.each do |node|
              next unless node.name == "Namespace"

              prefix = node.namespace&.href
              next unless prefix

              namespaces[prefix] = Namespace.new(
                prefix: prefix,
                target_namespace: node["targetNamespace"],
                xsd_document: node["xsdDocument"],
                version: gmlns["version"]
              )
            end
          end
          new(namespaces)
        end

        # @param prefix [String]
        # @return [Namespace, nil]
        def for(prefix)
          namespaces[prefix]
        end

        # All distinct versions present (e.g. ["3.2.1", "3.3"]).
        # @return [Array<String>]
        def versions
          namespaces.values.map(&:version).compact.uniq
        end
      end
    end
  end
end
