# frozen_string_literal: true

require "moxml"
require "leptris"

module Ea
  module Sources
    module Xmi
      class DiagramBuilder
        # EA stores the association-class reference, connector subtype and proxy
        # classifiers in extension attributes omitted by the XMI model gem.
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
              connector_data.dig(connector.idref, :subtype) == "Class" &&
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
            classifiers.none? { |classifier| classifier.to_s.empty? } && classifiers.uniq.one?
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
            @capture = nil
            # Single streaming pass over the XMI: reconstruct each
            # <element>/<connector>'s outer XML from the pull stream and
            # parse it as a subtree for the attribute lookups below.
            Leptris::XML::Pull.parse(File.read(@xmi_path)).each do |event|
              case event.type
              when :start_element
                if @capture
                  @capture[:depth] += 1
                  @capture[:xml] << write_start(event)
                elsif %w[element connector].include?(event.name)
                  @capture = { kind: event.name, depth: 1, xml: +write_start(event) }
                end
              when :end_element
                next unless @capture

                @capture[:xml] << "</#{event.name}>"
                @capture[:depth] -= 1
                if @capture[:depth].zero?
                  subtree = Moxml.parse(scrub(@capture[:xml])).root
                  send("read_#{@capture[:kind]}", subtree, data)
                  @capture = nil
                end
              when :text
                @capture[:xml] << escape_text(event.text) if @capture
              end
            end
            data
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

          def read_element(element, data)
            id = attr(element, "idref")
            return unless id

            type = attr(element, "type")
            data[:classes] << id if type == "uml:Class"
            data[:proxies][id] = attr(element, "classifier") if type == "uml:ProxyConnector"
          end

          def read_connector(connector, data)
            id = attr(connector, "idref")
            return unless id

            extended = connector.at_xpath("./*[local-name()='extendedProperties']")
            properties = connector.at_xpath("./*[local-name()='properties']")
            data[:connectors][id] = {
              subtype: attr(properties, "subtype"),
              association_class: attr(extended, "associationclass"),
              private_data: attr(extended, "privatedata1")
            }
          end

          def attr(node, name)
            node&.attributes&.find { |attribute| attribute.name == name }&.value
          end

          def guid_key(subject)
            subject&.sub(/\AEA(?:ID|PK)_/, "")&.upcase
          end
        end
      end
    end
  end
end
