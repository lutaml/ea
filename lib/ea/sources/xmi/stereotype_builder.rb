# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Extracts per-element stereotype applications from EA's
      # `<xmi:Extension>/<elements>` block. EA stores stereotype
      # info in `<element xmi:idref="EAID_...">/<properties
      # stereotype="X"/>`. The uml:Model packaged elements carry
      # type info but not stereotypes.
      #
      # Returns a Hash{element_id => Array<String>} of stereotype
      # names applied to that element.
      class StereotypeBuilder
        attr_reader :root

        def initialize(root)
          @root = root
        end

        def grouped_by_element
          @grouped ||= begin
            elements = root.extension&.elements
            return {} unless elements

            elements.element.each_with_object({}) do |ext_element, acc|
              id = ext_element.idref
              next unless id

              stereotypes = stereotypes_for(ext_element)
              next if stereotypes.empty?

              acc[id] = stereotypes
            end
          end
        end

        private

        # The `<properties stereotype="X"/>` attribute holds the
        # primary stereotype. Additional stereotypes from `<xrefs>`
        # are not captured here — that would require parsing the
        # packed XREFPROP string format.
        def stereotypes_for(ext_element)
          props = ext_element.properties
          value = props&.stereotype
          return [] if value.nil? || value.to_s.empty?

          [value.to_s]
        end
      end
    end
  end
end
