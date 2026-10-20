# frozen_string_literal: true

require "nokogiri"

module Ea
  module Sources
    module Xmi
      # The xmi gem omits ownedReception, so read those source members
      # directly rather than inferring operations from extension rows.
      class ReceptionBuilder
        def initialize(xmi_path)
          @xmi_path = xmi_path
        end

        def grouped_by_owner
          return {} unless @xmi_path

          @grouped_by_owner ||= read_receptions(Nokogiri::XML(File.read(@xmi_path)))
        end

        private

        def read_receptions(document)
          scopes = extension_scopes(document)
          xpath = '//*[local-name()="Model"]//*[local-name()="packagedElement"]/*[local-name()="ownedReception"]'
          document.xpath(xpath).each_with_object({}) do |node, grouped|
            owner_id = xmi_attribute(node.parent, "id")
            next unless owner_id

            (grouped[owner_id] ||= []) << build_one(node, owner_id, scopes)
          end
        end

        def build_one(node, owner_id, scopes)
          id = xmi_attribute(node, "id") ||
               IdNormalizer.synthetic_id(owner_id, "reception", node["name"])
          Ea::Model::Operation.new(
            id: id, name: node["name"], owner_id: owner_id,
            qualified_name: "#{node.parent["name"]}::#{node["name"]}",
            is_reception: true,
            visibility: node["visibility"] || scopes[id] || "public"
          )
        end

        def extension_scopes(document)
          xpath = '//*[local-name()="Extension"]//*[local-name()="receptions"]/*[local-name()="reception"]'
          document.xpath(xpath).each_with_object({}) do |node, scopes|
            id = xmi_attribute(node, "idref")
            scopes[id] = node["scope"].downcase if id && node["scope"]
          end
        end

        def xmi_attribute(node, name)
          node.at_xpath("@*[local-name()='#{name}']")&.value
        end
      end
    end
  end
end
