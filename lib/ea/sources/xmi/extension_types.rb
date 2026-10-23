# frozen_string_literal: true

require "nokogiri"

module Ea
  module Sources
    module Xmi
      # Type names EA stores in the <xmi:Extension><elements> block,
      # where the UML side only carries a primitive-type href or a
      # placeholder idref. The xmi gem does not expose operations or
      # parameters of the extension, so the raw XML is read once.
      #
      #   <attribute xmi:idref="ID"><properties type="int"/>
      #   <operation xmi:idref="ID"><type type="void"/>
      #   <parameter xmi:idref="ID"><properties type="int"/>
      class ExtensionTypes
        def self.from_path(xmi_path)
          return empty if xmi_path.nil?

          new(Nokogiri::XML(File.read(xmi_path)))
        end

        def self.empty
          new(nil)
        end

        def initialize(document)
          @attributes = index(document, "attribute", "properties")
          @attribute_stereotypes = index(document, "attribute", "stereotype", "stereotype")
          @returns = index(document, "operation", "type")
          @parameters = index(document, "parameter", "properties")
        end

        def attribute_type(id)
          @attributes[id]
        end

        # Stereotype EA stores on the attribute row
        # (<attribute><stereotype stereotype="voidable"/>).
        def attribute_stereotype(id)
          @attribute_stereotypes[id]
        end

        def return_type(operation_id)
          @returns[operation_id]
        end

        def parameter_type(parameter_id)
          @parameters[parameter_id]
        end

        private

        def index(document, owner, child, attribute = "type")
          return {} unless document

          document.xpath(%(//*[local-name()="#{owner}"][@*[local-name()="idref"]])).each_with_object({}) do |node, acc|
            type = node.at_xpath(%(*[local-name()="#{child}"]/@#{attribute}))&.value
            idref = node.at_xpath("@*[local-name()='idref']").value
            acc[idref] = type unless type.nil? || type.empty?
          end
        end
      end
    end
  end
end
