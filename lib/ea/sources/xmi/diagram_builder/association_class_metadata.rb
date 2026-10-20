# frozen_string_literal: true

require "nokogiri"

module Ea
  module Sources
    module Xmi
      class DiagramBuilder
        # EA stores the association-class reference and proxy classifiers in
        # extension attributes omitted by the XMI model gem.
        class AssociationClassMetadata
          def initialize(xmi_path)
            @xmi_path = xmi_path
          end

          def for(connector, placed_subjects:, waypoints:)
            return unless valid_tether?(connector, waypoints)

            attached_id = connector_data.dig(connector.idref, :association_class)
            return unless attached_id && class_ids.include?(attached_id)
            return unless placed_subjects.any? { |subject| guid_key(subject) == guid_key(attached_id) }

            attached_id
          end

          private

          def valid_tether?(connector, waypoints)
            @xmi_path && connector && association_class?(connector) &&
              proxy_pair?(connector) && coincident_route?(waypoints)
          end

          def association_class?(connector)
            connector.properties&.ea_type == "Association" &&
              connector.properties&.subtype == "Class" &&
              connector_data.dig(connector.idref, :private_data).to_s.match?(/\A[1-9]\d*\z/)
          end

          def proxy_pair?(connector)
            endpoints = [connector.source, connector.target]
            return false unless proxy_endpoints?(endpoints)

            classifiers = endpoints.map { |endpoint| proxy_classifiers[endpoint.idref] }
            matching_classifiers?(classifiers)
          end

          def proxy_endpoints?(endpoints)
            endpoints.all? { |endpoint| endpoint&.model&.type == "ProxyConnector" }
          end

          def matching_classifiers?(classifiers)
            classifiers.all?(&:itself) && classifiers.first == classifiers.last
          end

          def coincident_route?(waypoints)
            first = waypoints&.first&.position
            last = waypoints&.last&.position
            first && last && first.x == last.x && first.y == last.y
          end

          def connector_data
            @connector_data ||= read_metadata.fetch(:connectors)
          end

          def proxy_classifiers
            @proxy_classifiers ||= read_metadata.fetch(:proxies)
          end

          def class_ids
            @class_ids ||= read_metadata.fetch(:classes)
          end

          def read_metadata
            @read_metadata ||= scan_metadata
          end

          def scan_metadata
            data = { connectors: {}, proxies: {}, classes: [] }
            File.open(@xmi_path) do |file|
              Nokogiri::XML::Reader(file).each { |node| read_node(node, data) }
            end
            data
          end

          def read_node(node, data)
            return unless node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT

            read_element(node, data) if node.local_name == "element"
            read_connector(node, data) if node.local_name == "connector"
          end

          def read_element(node, data)
            element = Nokogiri::XML(node.outer_xml).root
            id = attr(element, "idref")
            return unless id

            type = attr(element, "type")
            data[:classes] << id if type == "uml:Class"
            data[:proxies][id] = attr(element, "classifier") if type == "uml:ProxyConnector"
          end

          def read_connector(node, data)
            connector = Nokogiri::XML(node.outer_xml).root
            id = attr(connector, "idref")
            return unless id

            extended = connector.at_xpath("./*[local-name()='extendedProperties']")
            data[:connectors][id] = {
              association_class: attr(extended, "associationclass"),
              private_data: attr(extended, "privatedata1")
            }
          end

          def attr(node, name)
            node&.attribute_nodes&.find { |attribute| attribute.name == name }&.value
          end

          def guid_key(subject)
            subject&.sub(/\AEA(?:ID|PK)_/, "")&.upcase
          end
        end
      end
    end
  end
end
