# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Walks the <xmi:Extension>/<elements> block for a single
      # EA diagram. Returns two arrays: placed elements and placed
      # connectors, each carrying the parsed geometry + style data.
      #
      # The xmi gem exposes the raw rows via Sparx::Diagram::Elements.
      # This class adds EA-aware parsing on top.
      class ExtensionElements
        attr_reader :diagram

        def initialize(diagram)
          @diagram = diagram
        end

        def placed_elements
          rows.filter_map { |row| build_placed_element(row) }
        end

        def placed_connectors
          rows.filter_map { |row| build_placed_connector(row) }
        end

        private

        def rows
          elements_collection = diagram&.elements
          return [] unless elements_collection

          elements_collection.element.to_a
        end

        def build_placed_element(row)
          return nil unless row.subject

          placement = ExtensionGeometryParser.parse(row.geometry)
          return nil unless placement.left || placement.img_left

          style = ExtensionStyleParser.parse(row.style)
          PlacedElement.new(
            subject: row.subject,
            seqno: row.seqno,
            geometry: placement,
            style: style
          )
        end

        def build_placed_connector(row)
          return nil unless row.subject

          placement = ExtensionGeometryParser.parse(row.geometry)
          style = ExtensionStyleParser.parse(row.style)
          # Connectors carry SOID/EOID in their style; geometry has
          # only bend routing.
          return nil unless style.soid && style.eoid

          PlacedConnector.new(
            subject: row.subject,
            geometry: placement,
            style: style
          )
        end

        # Value types — the diagram builder translates these into
        # Ea::Model::DiagramElement / DiagramConnector.
        PlacedElement = Struct.new(:subject, :seqno, :geometry, :style, keyword_init: true)
        PlacedConnector = Struct.new(:subject, :geometry, :style, keyword_init: true)
      end
    end
  end
end
