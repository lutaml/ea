# frozen_string_literal: true

require "nokogiri"

module Ea
  module Sources
    module Xmi
      # Extracts tagged values from the `<xmi:Extension><tags><tag/>`
      # block. The xmi gem does not expose Sparx tags directly, so we
      # parse the raw XML once and group tags by their
      # `modelElement` attribute. Each tag's value is truncated at
      # the first `#` (EA encodes notes after that marker).
      class TagBuilder
        attr_reader :xmi_path

        def initialize(xmi_path)
          @xmi_path = xmi_path
        end

        # Returns Hash{model_element_id => Array<Ea::Model::TaggedValue>}
        def grouped_by_model_element
          return {} if xmi_path.nil?

          @grouped ||= begin
            doc = Nokogiri::XML(File.read(xmi_path))
            # <tags><tag/></tags> lives inside per-element <element>
            # blocks within <xmi:Extension>. The element itself is in
            # no XML namespace; match by local-name to be safe.
            doc.xpath(%(//*[local-name()="tags"]/*[local-name()="tag"]))
              .each_with_object({}) do |node, acc|
              me = node["modelElement"]
              next unless me

              key = node["name"].to_s
              value = node["value"].to_s.split("#", 2).first
              next if key.empty?

              (acc[me] ||= []) << Ea::Model::TaggedValue.new(key: key, value: value)
            end
          end
        end
      end
    end
  end
end
