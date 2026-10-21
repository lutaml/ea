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
      # `uml:Text` elements are projected the same way; those whose
      # CustomProperties xref carries legend configuration also
      # get an `Ea::Model::Legend` payload.
      class NoteBuilder
        NOTE_TYPES = { "uml:Note" => "Note", "uml:Text" => "Text" }.freeze

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
          note_type = NOTE_TYPES[ext_element.type]
          return nil unless note_type

          Ea::Model::Note.new(
            id: ext_element.idref,
            name: ext_element.name,
            body: ext_element.properties&.documentation,
            note_type: note_type,
            legend: legend_for(ext_element, note_type),
            package_id: IdNormalizer.from_xmi_id(ext_element.model&.package)
          )
        end

        def legend_for(ext_element, note_type)
          return nil unless note_type == "Text"

          LegendBuilder.new(ext_element.xrefs&.value).build
        end
      end
    end
  end
end
