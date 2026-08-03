# frozen_string_literal: true

require "nokogiri"

module Ea
  module Sources
    module Xmi
      # Extracts Note elements from EA's XMI extension block.
      # Notes are documentation entries (`<element xmi:type="uml:Note">`)
      # inside `<xmi:Extension>/<elements>`. Each carries a
      # `<properties documentation="..."/>` child with the body text.
      #
      # The xmi gem parses Note elements as part of the extension
      # block; we walk them and project to Ea::Model::Note.
      class NoteBuilder
        attr_reader :root

        def initialize(root)
          @root = root
        end

        def build_all
          elements = root.extension&.elements
          return [] unless elements

          elements.element.to_a.filter_map { |e| build_one(e) }
        end

        private

        def build_one(ext_element)
          type = ext_element.type
          return nil unless type == "uml:Note"

          props = ext_element.properties
          Ea::Model::Note.new(
            id: ext_element.idref,
            name: ext_element.name,
            body: props&.documentation,
            note_type: "Note"
          )
        end
      end
    end
  end
end
