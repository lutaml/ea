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

        def doc
          @doc ||= Nokogiri::XML(File.read(xmi_path))
        end

        def keywords_by_diagram
          @keywords_by_diagram ||= begin
            result = {}
            # The Sparx XMI export declares the umldi: namespace
            # but the elements inside Diagram have lost their
            # prefix binding once parsed by Nokogiri — the
            # element name resolves to local-name "ownedElement"
            # and the umldi:UMLClassifierShape type information
            # lives in the literal `type` attribute. We therefore
            # match shape children by the presence of `modelElement`
            # and the keyword label by its `text` attribute.
            doc.xpath("//*[local-name()=\"Diagram\"]").each do |diagram|
              diagram_id = diagram["id"] || diagram["xmi:id"]
              next unless diagram_id

              keywords = {}
              diagram.xpath("./ownedElement[@modelElement]").each do |shape|
                model_id = shape["modelElement"]
                next unless model_id

                # Keyword label is the first ownedElement child
                # with a non-empty `text` attribute. The name
                # label follows it.
                shape.xpath("./ownedElement[@text]").each do |child|
                  text = child["text"]
                  next if text.nil? || text.empty?
                  next if text.start_with?("«") # safety

                  keywords[model_id] = text
                  break
                end
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
