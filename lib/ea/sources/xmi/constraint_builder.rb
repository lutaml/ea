# frozen_string_literal: true

require "leptris"

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
          @seen_owners = {}
          @blocks_seen = {}
          @skip_block = false
          Leptris::XML::Pull.parse(File.read(xmi_path)).each { |event| visit(event) }
          @grouped
        end

        def visit(event)
          case event.type
          when :end_element
            @owner = nil if @path.pop == "element"
          when :start_element
            enter(event)
            @path.push(event.name)
          end
        end

        def enter(event)
          if event.name == "element" && @path.last == "elements"
            @owner = first_block_owner(event.attrs&.fetch("xmi:idref", nil))
          elsif event.name == "constraints" && @owner && @path.last == "element"
            @skip_block = @blocks_seen.key?(@owner)
            @blocks_seen[@owner] = true
          elsif event.name == "constraint" && @owner && !@skip_block && @path.last(2) == %w[element constraints]
            (@grouped[@owner] ||= []) << constraint(event)
          end
        end

        # A repeated `<element xmi:idref="X">` or `<constraints>` block would
        # append X's constraints again, so only the first of each is read.
        def first_block_owner(idref)
          return nil if @seen_owners.key?(idref)

          @seen_owners[idref] = true
          idref
        end

        def constraint(node)
          Ea::Model::Constraint.new(
            id: IdNormalizer.synthetic_id(@owner, "constraint", @grouped[@owner].to_a.size.to_s),
            name: node.attrs&.fetch("name", nil).to_s,
            kind: node.attrs&.fetch("type", nil).to_s,
            body: node.attrs&.fetch("description", nil).to_s,
            status: node.attrs&.fetch("status", nil).to_s
          )
        end
      end
    end
  end
end
