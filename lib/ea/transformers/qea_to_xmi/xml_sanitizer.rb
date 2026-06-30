# frozen_string_literal: true

require "nokogiri"

module Ea
  module Transformers
    module QeaToXmi
      # Removes truly-empty elements (`<generalization/>`, `<ownedEnd/>`,
      # etc.) from a serialized XMI document.
      #
      # Sparx XMI carries no empty child elements — every `<ownedEnd>`,
      # `<generalization>`, `<lowerValue>` either has attributes or is
      # omitted entirely. The xmi gem's UML models, however, declare
      # `value_map: Xmi::VALUE_MAP` on every collection mapping. That
      # VALUE_MAP is round-trip-oriented: it forces empty-element
      # emission so the parser can distinguish absence from emptiness
      # on the way back in. For *generation* from a QEA database, those
      # empty elements are pure noise — they bloat the output and break
      # count-parity with real Sparx XMI.
      #
      # This class is the workaround until the xmi gem Phase 2 work
      # introduces a generation-friendly value_map (see TODO.next/21 §1).
      # When that lands, this entire file can be deleted in a one-line
      # change to the Transformer.
      #
      # Algorithm: depth-first post-order removal. Removing the deepest
      # empty element first means its parent's emptiness is checked
      # against the already-pruned subtree — single pass, O(N).
      class XmlSanitizer
        # @param xml [String] serialized XMI document
        # @return [String] the same document with truly-empty elements
        #   (no children, no text, no attributes) removed
        def self.call(xml)
          new(xml).call
        end

        def initialize(xml)
          @doc = Nokogiri::XML(xml)
        end

        def call
          # Never prune the root — even if it becomes empty after its
          # children are stripped, removing it would produce an empty
          # document. Walk only its descendants.
          return "" unless @doc.root

          @doc.root.element_children.each { |child| prune_empty(child) }
          @doc.to_xml
        end

        private

        def prune_empty(node)
          node.element_children.each { |child| prune_empty(child) }
          return unless empty?(node)

          node.remove
        end

        def empty?(node)
          node.element_children.empty? &&
            node.text.strip.empty? &&
            node.attributes.empty?
        end
      end
    end
  end
end
