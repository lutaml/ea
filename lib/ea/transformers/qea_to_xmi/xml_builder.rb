# frozen_string_literal: true

require "nokogiri"

module Ea
  module Transformers
    module QeaToXmi
      # XML builder that produces Sparx XMI's mixed-prefix style.
      #
      # Nokogiri::XML::Builder propagates the most recently used namespace
      # prefix to all children unless explicitly reset, which makes it
      # impossible to emit `<uml:Model>` followed by UNPREFIXED descendants
      # like `<packagedElement>` (the Sparx XMI convention).
      #
      # This builder uses the lower-level `Nokogiri::XML::Document` API so
      # each element picks its own prefix from {PREFIXED_ELEMENTS} —
      # everything not in that hash is emitted with no prefix regardless of
      # the parent. Element creation uses a method-per-tag API so emitters
      # can call `xml.packagedElement(attrs) { ... }` exactly as before.
      class XmlBuilder
        # Local name → namespace prefix map. Any element not listed here
        # is emitted in no namespace, matching the Sparx XMI convention
        # where only the root framing elements carry a prefix.
        PREFIXED_ELEMENTS = {
          "XMI"           => :xmi,
          "Documentation" => :xmi,
          "Model"         => :uml,
        }.freeze

        def initialize(encoding: "UTF-8")
          @doc = Nokogiri::XML::Document.new
          @doc.encoding = encoding
          @parent_stack = [@doc]
          @namespace_by_prefix = {}
        end

        # Emits the XMI root element. Namespace declarations must be passed
        # as `xmlns:` attributes; their prefix refs are captured so that
        # later {#method_missing} dispatch can attach them by prefix.
        # @param namespaces [Hash{String,Symbol=>String}] xmlns:* declarations
        # @yieldparam builder [XmlBuilder]
        # @return [Nokogiri::XML::Node]
        def root(namespaces = {})
          node = @doc.create_element("XMI")
          apply_attributes_and_namespaces(node, namespaces)
          capture_namespace_refs(node)
          node.namespace = @namespace_by_prefix[:xmi]
          @doc.root = node
          @parent_stack = [node]
          yield self if block_given?
          node
        end

        def to_xml
          @doc.to_xml
        end

        def respond_to_missing?(_, _ = false)
          true
        end

        # Emits one element named after the method. If the tag is in
        # {PREFIXED_ELEMENTS}, its namespace is set explicitly; otherwise
        # the element is created in no namespace regardless of the parent.
        def method_missing(name, *args, &block)
          tag = name.to_s
          attrs = args.first.is_a?(Hash) ? args.first : {}
          node = @doc.create_element(tag, attrs)
          ns = @namespace_by_prefix[PREFIXED_ELEMENTS[tag]]
          node.namespace = ns if ns
          @parent_stack.last.add_child(node)
          if block_given?
            @parent_stack.push(node)
            begin
              yield self
            ensure
              @parent_stack.pop
            end
          end
          node
        end

        private

        def apply_attributes_and_namespaces(node, namespaces)
          namespaces.each do |key, value|
            k = key.to_s
            if k.start_with?("xmlns:")
              node.add_namespace_definition(k.delete_prefix("xmlns:"), value)
            else
              node[k] = value
            end
          end
        end

        def capture_namespace_refs(node)
          node.namespace_definitions.each do |ns|
            @namespace_by_prefix[ns.prefix.to_sym] = ns
          end
        end
      end
    end
  end
end
