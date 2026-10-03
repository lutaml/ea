# frozen_string_literal: true

require "moxml"

module Ea
  module Xmi
    # Prunes an EA XMI export to the subgraphs reachable from sets of
    # (package name, element name) pairs, so the existing parse pipeline
    # hydrates small slices instead of the whole export. A plateau-scale
    # export is 98 MB, more than half of it diagram presentation data
    # that no table reads, and materializing the whole Xmi tree plus the
    # Ea graph costs 10+ GB of live objects.
    #
    # The closure is generic: every attribute value that looks like an EA
    # element id (EAID_/EAPK_/EAEM_) found anywhere inside a kept
    # element's subtree keeps the referenced element too, transitively -
    # no XMI semantics are encoded here. Only container tags are
    # membership-gated (packagedElement in the model, element and
    # connector in the extension); anything nested inside a kept
    # container is copied verbatim. The diagrams section is dropped.
    #
    # `slices` performs one index pass and one write pass and emits one
    # standalone slice per requested group, so each consumer (one macro,
    # one class table) hydrates only its own class's subgraph: the
    # per-parse peak is the size of one slice, not of the export.
    class Slicer
      EA_ID_RE = /\A(?:EAID|EAPK|EAEM)_[0-9A-Za-z_]+\z/
      private_constant :EA_ID_RE

      XML_DECL = %(<?xml version="1.0" encoding="UTF-8"?>\n)
      private_constant :XML_DECL

      # Containers whose membership is gated against the keep set, by
      # document section. umldi:Diagram carries the embedded diagram
      # shapes (tens of MB with waypoints and bounds in an EA export)
      # and is never referenced by table content, so it gates on the
      # keep set as well.
      GATED = {
        model: ["packagedElement", "umldi:Diagram"].freeze,
        elements: ["element"].freeze,
        connectors: ["connector"].freeze,
      }.freeze
      private_constant :GATED

      SECTION_CHILD = {
        "elements" => :elements,
        "connectors" => :connectors,
        "diagrams" => :drop,
        "profiles" => :drop,
      }.freeze
      private_constant :SECTION_CHILD

      Node = Struct.new(:id, :tag, :xmi_type, :name, :parent_id, :section,
                        :refs, keyword_init: true)

      class << self
        # Single slice for one wanted set.
        # wanted: array of [package_name, element_name]; package may be
        # nil, in which case elements match by name in any package.
        def call(source, wanted, output)
          new(source).single(wanted, output)
          output
        end

        # One index pass, one write pass, one standalone slice per group.
        # groups: hash key => wanted array (same shape as +wanted+
        # above). Returns { key => slice size in bytes }.
        def slices(source, groups, dir:, prefix: "slice")
          new(source).multi(groups, dir: dir, prefix: prefix)
        end
      end

      def initialize(source)
        @source = source
        @moxml = Moxml.new(:leptris)
      end

      def single(wanted, output)
        nodes = index_pass
        keep = closure(nodes, seed_ids(nodes, wanted))
        writer = GroupWriter.new([keep], [output])
        @moxml.sax_parse(source_string, writer)
        self
      end

      # Returns { group key => slice path }; groups whose wanted set
      # matches nothing are skipped entirely so callers can fall back
      # to the full source.
      def multi(groups, dir:, prefix: "slice")
        require "fileutils"
        FileUtils.mkdir_p(dir)
        nodes = index_pass
        keeps = []
        outputs = []
        paths = {}
        groups.each do |key, wanted|
          seeds = seed_ids(nodes, wanted)
          next if seeds.empty?

          keeps << closure(nodes, seeds)
          file = File.join(dir, "#{prefix}_#{key.hash.abs}.xmi")
          outputs << File.open(file, "w")
          paths[key] = file
        end
        @moxml.sax_parse(source_string, GroupWriter.new(keeps, outputs))
        outputs.each(&:close)
        paths
      end

      private

      # --- pass one: index id-bearing containers and their references --

      class IndexHandler < ::Moxml::SAX::Handler
        attr_reader :nodes

        def initialize
          @nodes = {}
          @stack = [] # [id_or_nil, shared_refs_array]
          @section = []
          @refs_off = 0
        end

        # Only gated containers become nodes (packagedElement in the
        # model, element and connector in the extension, and the
        # embedded umldi:Diagram blocks). Other id-bearing elements -
        # `<type xmi:idref>`, `<model package>` and the like - are pure
        # references: recording them as nodes would let a reference
        # define the element's ancestry, so their EA-id values flow into
        # the enclosing container's reference set instead.
        def on_start_element(name, attributes = {}, _namespaces = {})
          @section << section_for(name, @section.last)
          @refs_off += 1 if name == "links"
          id = attributes["xmi:id"] || attributes["xmi:idref"]
          is_node = id && GATED.fetch(@section.last, []).include?(name)
          if is_node && (existing = @nodes[id])
            # A container id occurs twice in an EA export: as the model
            # element (uml:Model subtree) and as the extension entry
            # keyed by xmi:idref. Merge so one node carries the model
            # ancestry and both occurrences' references; the entry
            # usually carries the name.
            existing.name ||= attributes["name"]
            existing.xmi_type ||= attributes["xmi:type"]
            collect_refs(attributes, existing.refs)
            @stack << [id, existing.refs]
            return
          end
          refs = is_node ? [] : (@stack.last ? @stack.last[1] : [])
          @stack << [is_node ? id : nil, refs]
          unless is_node
            collect_refs(attributes, refs)
            return
          end

          @nodes[id] = Node.new(
            id: id, tag: name,
            xmi_type: attributes["xmi:type"], name: attributes["name"],
            parent_id: nearest_id, section: @section.last, refs: refs,
          )
          collect_refs(attributes, refs)
        end

        def on_end_element(name)
          @refs_off -= 1 if name == "links"
          @stack.pop
          @section.pop
        end

        private

        def nearest_id
          @stack.reverse_each do |id, _|
            return id if id
          end
          nil
        end

        def section_for(name, current)
          return :model if name == "uml:Model"
          return :extension if name == "xmi:Extension"

          if current == :extension
            SECTION_CHILD[name] || :drop
          elsif current == :drop
            :drop
          else
            current
          end
        end

        # The links blocks inside extension entries restate every
        # relation's endpoints; the connector records in the connectors
        # section already carry both ends, so collecting from links
        # would pull the endpoint classes of every relation into the
        # closure transitively (half the model per class).
        def collect_refs(attributes, refs)
          return if @refs_off.positive?

          attributes.each_value do |v|
            refs << v if v.is_a?(String) && v.match?(EA_ID_RE)
          end
        end
      end

      def index_pass
        handler = IndexHandler.new
        @moxml.sax_parse(source_string, handler)
        handler.nodes
      end

      def source_string
        @source.is_a?(IO) || @source.is_a?(StringIO) ? @source.read : File.read(@source)
      end

      # --- closure ------------------------------------------------------

      def closure(nodes, seeds)
        keep = {}
        frontier = seeds.dup
        until frontier.empty?
          id = frontier.pop
          next if keep[id]

          node = nodes[id]
          next unless node

          keep[id] = true
          frontier.concat(node.refs)
          # keeping a model element keeps its package ancestry
          if node.section == :model
            anc = nodes[node.parent_id]
            while anc && !keep[anc.id]
              keep[anc.id] = true
              frontier.concat(anc.refs) unless anc.section == :model
              anc = nodes[anc.parent_id]
            end
          end
        end
        keep
      end

      def seed_ids(nodes, wanted)
        seeds = []
        wanted.each do |package, name|
          named = nodes.values.select { |n| n.name == name }
          next if named.empty?

          # package-anchored matches first; consumers resolve by name,
          # so when no package chain matches, every same-named element
          # is seeded and the resolver picks among them as usual
          anchored = package ? named.select { |n| under_package?(n, package, nodes) } : []
          (anchored.empty? ? named : anchored).each { |n| seeds << n.id }
        end
        seeds.uniq
      end

      def under_package?(node, package, nodes)
        anc = nodes[node.parent_id]
        while anc && anc.id != node.id
          return true if anc.name == package && anc.xmi_type == "uml:Package"

          anc = nodes[anc.parent_id]
        end
        false
      end

      # --- pass two: re-serialize the kept subtrees, per group ----------

      class GroupWriter < ::Moxml::SAX::Handler
        def initialize(keeps, outputs)
          @keeps = keeps
          @outputs = outputs
          @open = []   # [name, keys] - keys = group indexes keeping this element
          @section = []
        end

        def on_start_document
          @outputs.each { |io| io << XML_DECL }
        end

        def on_start_element(name, attributes = {}, namespaces = {})
          section = section_for(name, @section.last)
          @section << section
          parent_keys = @open.empty? ? (0...@keeps.size).to_a : @open.last[1]
          keys =
            if section == :drop
              []
            elsif GATED[section]&.include?(name)
              id = attributes["xmi:id"] || attributes["xmi:idref"]
              if id
                parent_keys.select { |i| @keeps[i][id] }
              else
                parent_keys.dup
              end
            else
              parent_keys
            end
          @open << [name, keys]
          return if keys.empty?

          tag = +"<#{name}"
          namespaces.each { |p, u| tag << %( xmlns:#{p}="#{esc_attr(u)}") }
          attributes.each { |k, v| tag << %( #{k}="#{esc_attr(v)}") }
          tag << ">"
          keys.each { |i| @outputs[i] << tag }
        end

        def on_end_element(name)
          frame = @open.pop
          @section.pop
          frame[1].each { |i| @outputs[i] << "</#{name}>" } unless frame[1].empty?
        end

        def on_characters(text)
          return if @open.empty? || @open.last[1].empty?

          escaped = esc_text(text)
          @open.last[1].each { |i| @outputs[i] << escaped }
        end

        def on_cdata(text)
          return if @open.empty? || @open.last[1].empty?

          chunk = "<![CDATA[#{text}]]>"
          @open.last[1].each { |i| @outputs[i] << chunk }
        end

        private

        def section_for(name, current)
          return :model if name == "uml:Model"
          return :extension if name == "xmi:Extension"

          if current == :extension
            SECTION_CHILD[name] || :drop
          elsif current == :drop
            :drop
          else
            current
          end
        end

        def esc_attr(value)
          value.gsub(/[&<>"]/) do |c|
            { "&" => "&amp;", "<" => "&lt;", ">" => "&gt;", '"' => "&quot;" }[c]
          end
        end

        def esc_text(value)
          value.gsub(/[&<>]/) do |c|
            { "&" => "&amp;", "<" => "&lt;", ">" => "&gt;" }[c]
          end
        end
      end
    end
  end
end
