# frozen_string_literal: true

require "nokogiri"

module Ea
  module Sources
    module Xmi
      # Extracts element constraints from the `<xmi:Extension><elements>`
      # block (`<element><constraints><constraint/></constraints>`), the
      # XMI image of t_objectconstraint. The xmi gem does not expose them,
      # so the file is streamed once and grouped by owning element id.
      class ConstraintBuilder
        attr_reader :xmi_path

        def initialize(xmi_path)
          @xmi_path = xmi_path
        end

        # Returns Hash{element_id => Array<Ea::Model::Constraint>}
        def grouped_by_element
          return {} if xmi_path.nil?

          @grouped_by_element ||= scan
        end

        private

        def scan
          @path = []
          @owner = nil
          @grouped = {}
          File.open(xmi_path) { |io| Nokogiri::XML::Reader(io).each { |node| visit(node) } }
          @grouped
        end

        def visit(node)
          case node.node_type
          when Nokogiri::XML::Reader::TYPE_END_ELEMENT
            @owner = nil if @path.pop == "element"
          when Nokogiri::XML::Reader::TYPE_ELEMENT
            enter(node)
            @path.push(node.local_name) unless node.self_closing?
          end
        end

        def enter(node)
          if node.local_name == "element" && @path.last == "elements" && !node.self_closing?
            @owner = node.attribute("xmi:idref")
          elsif node.local_name == "constraint" && @owner && @path.last(2) == %w[element constraints]
            (@grouped[@owner] ||= []) << constraint(node)
          end
        end

        def constraint(node)
          Ea::Model::Constraint.new(
            id: IdNormalizer.synthetic_id(@owner, "constraint", @grouped[@owner].to_a.size.to_s),
            name: node.attribute("name").to_s,
            kind: node.attribute("type").to_s,
            body: node.attribute("description").to_s,
            status: node.attribute("status").to_s
          )
        end
      end
    end
  end
end
