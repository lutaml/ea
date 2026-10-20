# frozen_string_literal: true

require "nokogiri"

module Ea
  module Sources
    module Xmi
      class DiagramBuilder
        # The XMI gem omits role stereotypes. Stream the saved connector
        # records once, without retaining another full XML document.
        class ConnectorMetadata
          def initialize(xmi_path)
            @xmi_path = xmi_path
          end

          def for(connector)
            {
              source_stereotype: role_stereotypes.dig(connector.idref, :source),
              target_stereotype: role_stereotypes.dig(connector.idref, :target),
              is_substitutable: false_substitutability?(connector.xrefs&.value.to_s)
            }
          end

          private

          def false_substitutability?(xrefs)
            xrefs.scan(/\$XREFPROP=(.*?)\$ENDXREF;/m).any? do |match|
              record = match.first
              next false unless record.include?("$NAM=CustomProperties$NAM;") &&
                                record.include?("$TYP=connector property$TYP;")

              values = record.scan(/@PROP=(.*?)@ENDPROP;/m).filter_map do |property|
                substitutability_value(property.first)
              end
              !values.empty? && !values.include?("-1")
            end
          end

          def substitutability_value(property)
            return unless property.include?("@NAME=isSubstitutable@ENDNAME;") &&
                          property.include?("@TYPE=Boolean@ENDTYPE;")

            property[/@VALU=(.*?)@ENDVALU;/m, 1]
          end

          def role_stereotypes
            @role_stereotypes ||= read_role_stereotypes
          end

          def read_role_stereotypes
            return {} unless @xmi_path

            File.open(@xmi_path) do |file|
              Nokogiri::XML::Reader(file).each_with_object({}) do |node, roles|
                next unless node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT && node.local_name == "connector"

                read_connector_roles(node, roles)
              end
            end
          end

          def read_connector_roles(node, roles)
            connector = Nokogiri::XML(node.outer_xml).root
            id = connector.at_xpath("@*[local-name()='idref']")&.value
            return unless id

            roles[id] = %i[source target].to_h do |side|
              value = connector.at_xpath("./*[local-name()='#{side}']/*[local-name()='role']/@stereotype")&.value
              [side, value]
            end
          end
        end
      end
    end
  end
end
