# frozen_string_literal: true

require "nokogiri"

module Ea
  module Sources
    module Xmi
      # Reads UMLDI `<ownedElement>` blocks from the XMI source and
      # returns the keyword text EA emitted for each modeled element.
      #
      # The xmi gem's typed parser does not surface umldi: keyword
      # labels, but EA encodes them as
      # `<ownedElement xmi:type="umldi:UMLKeywordLabel" text="Type"/>`.
      # This class pre-parses the raw XML once and indexes by the
      # referenced classifier ID.
      #
      # Returned text is the raw keyword ("Type", "FeatureType",
      # "dataType"). The emitter wraps it in «...» when rendering.
      class UmldiKeywordExtractor
        # Sparx EA 6.5 declares umldi: as the 20161101 namespace on
        # the XMI root. Older EAs use the 20131001 version. Try both.
        UMLDI_NAMESPACES = [
          "http://www.omg.org/spec/UML/20161101/UMLDI",
          "http://www.omg.org/spec/UML/20131001/UMLDI"
        ].freeze

        attr_reader :xmi_path

        def initialize(xmi_path)
          @xmi_path = xmi_path
        end

        # Returns { classifier_id => keyword_text } for every
        # umldi:UMLKeywordLabel found, scoped to the given diagram.
        def keywords_for_diagram(diagram_id)
          return {} unless File.exist?(xmi_path)

          keywords_by_diagram[diagram_id] || {}
        end

        private

        # EA can save both a built-in keyword and a custom stereotype label.
        # Prefer the label matching the element's saved stereotype, if present.
        def keyword_text(shape)
          labels = shape.xpath("./ownedElement[@*[local-name()=\"type\"]=\"umldi:UMLKeywordLabel\"]")
          stereotype = stereotypes_by_element[shape["modelElement"]]
          label = labels.find { |candidate| stereotype && candidate["text"] == stereotype } || labels.first
          text = label && label["text"]
          text unless text.nil? || text.empty?
        end

        def stereotypes_by_element
          @stereotypes_by_element ||= doc.xpath("//*[local-name()=\"Extension\"]/elements/element")
                                         .each_with_object({}) do |element, result|
                                           stereotype = element.at_xpath("./properties")&.[]("stereotype")
                                           result[element["idref"] || element["xmi:idref"]] = stereotype if stereotype
                                         end
        end

        def doc
          @doc ||= Nokogiri::XML(File.read(xmi_path))
        end

        def keywords_by_diagram
          @keywords_by_diagram ||= begin
            result = {}
            doc.xpath("//*[local-name()=\"Diagram\"]").each do |diagram|
              diagram_id = diagram["id"] || diagram["xmi:id"]
              next unless diagram_id

              keywords = {}
              diagram.xpath("./ownedElement[@modelElement]").each do |shape|
                text = keyword_text(shape)
                keywords[shape["modelElement"]] = text if text
              end
              result[diagram_id] = keywords unless keywords.empty?
            end
            result
          end
        end
      end
    end
  end
end
