# frozen_string_literal: true

require "moxml"
require "leptris"

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

            capture_connectors(File.read(@xmi_path)).each_with_object({}) do |connector, roles|
              read_connector_roles(connector, roles)
            end
          end

          # Single streaming pass over the XMI: reconstruct each
          # <connector>'s outer XML from the pull stream and parse it as a
          # subtree for the role lookups below.
          def capture_connectors(xml)
            connectors = []
            buffer = nil
            depth = 0

            Leptris::XML::Pull.parse(xml).each do |event|
              case event.type
              when :start_element
                if buffer
                  buffer << write_start(event)
                  depth += 1
                elsif event.name == "connector"
                  buffer = +write_start(event)
                  depth = 1
                end
              when :end_element
                next unless buffer

                buffer << "</#{event.name}>"
                depth -= 1
                if depth.zero?
                  connectors << Moxml.parse(scrub(buffer)).root
                  buffer = nil
                end
              when :text
                buffer << escape_text(event.text) if buffer
              end
            end
            connectors
          end

          # EA XMI files occasionally carry bytes outside the declared
          # encoding; the nokogiri outer-xml path tolerated them, so scrub
          # the reconstructed fragment the same way before parsing.
          def scrub(buffer)
            buffer.encode("UTF-8", invalid: :replace, undef: :replace)
          end

          def write_start(event)
            attrs = (event.attrs || {}).map do |key, value|
              %( #{key}="#{escape_attribute(value)}")
            end.join
            "<#{event.name}#{attrs}>"
          end

          def escape_attribute(value)
            value.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub('"', "&quot;")
          end

          def escape_text(text)
            text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
          end

          def read_connector_roles(connector, roles)
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
