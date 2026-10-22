# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # EA paints connectors (each line followed by its heads) ordered by the
      # start element's placement row, then the connector id: the
      # `paint_order` key the diagram builders store. Verified without a
      # single inversion over 12785 connector pairs of the QEA corpus.
      # Connectors with an unresolvable key (empty, or with a nil part)
      # follow the keyed ones, and phantoms (no stored key) come last, each
      # in link order.
      module PaintOrder
        module_function

        def connectors(diagram)
          (diagram.connectors || []).each_with_index.sort_by do |connector, index|
            order = connector.paint_order
            rank = if order.nil?
                     2
                   else
                     order.empty? || order.any?(&:nil?) ? 1 : 0
                   end
            [rank, rank.zero? ? order : [], index]
          end.map(&:first)
        end
      end
    end
  end
end
