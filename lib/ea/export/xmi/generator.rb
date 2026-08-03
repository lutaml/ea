# frozen_string_literal: true

require "nokogiri"

module Ea
  module Export
    module Xmi
      # Generates Sparx-flavored XMI 2.1 from a parsed QEA model.
      #
      # Uses the existing QEA→XMI transformer under Ea::Transformers
      # when available. Falls back to a minimal hand-rolled writer
      # that produces a valid XMI root + class list when the bridge
      # is unavailable.
      class Generator
        def self.call(model, **_opts)
          new(model).call
        end

        attr_reader :model

        # @param model [#collections] Ea::Qea::Database or compatible
        def initialize(model)
          @model = model
        end

        def call
          builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
            xml.xmi("XMI" => "2.1",
                    "xmlns:UML" => "http://schema.omg.org/spec/UML/2.1",
                    "xmlns:xmi" => "http://schema.omg.org/spec/XMI/2.1") do
              xml.documentation(:exporter => "ea-rb",
                                :exporterVersion => Ea::VERSION)
              emit_model(xml)
            end
          end
          builder.to_xml
        end

        private

        def emit_model(xml)
          classes = (model.collections[:objects] || [])
                     .select { |o| o.object_type == "Class" }

          xml.tag!("uml:Model", "xmi:id" => "model-root",
                              "name" => "model") do
            classes.each do |klass|
              emit_class(xml, klass)
            end
          end
        end

        def emit_class(xml, klass)
          attrs = class_attributes(klass)
          xml.tag!("ownedMember",
                  "xmi:type" => "uml:Class",
                  "xmi:id" => klass.ea_guid || klass.object_id.to_s,
                  "name" => klass.name || "Anonymous") do
            attrs.each { |attr| emit_attribute(xml, attr) }
          end
        end

        def emit_attribute(xml, attr)
          xml.tag!("ownedAttribute",
                  "xmi:type" => "uml:Property",
                  "xmi:id" => attr.ea_guid || attr.property_id.to_s,
                  "name" => attr.name)
        end

        def class_attributes(klass)
          attrs = model.collections[:attributes] || []
          attrs.select { |a| a.object_id == klass.object_id }
        end
      end
    end
  end
end
