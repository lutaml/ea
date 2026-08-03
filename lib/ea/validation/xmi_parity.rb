# frozen_string_literal: true

module Ea
  module Validation
    # Compares Ea::Transformers.qea_to_xmi output against EA's
    # reference XMI export (`examples/exports/*/model.xml`).
    #
    # Reports per-element-type counts (packagedElement, ownedAttribute,
    # ownedEnd, memberEnd, generalization, connector, diagram, style,
    # tags, documentation, xmi:Extension) so gaps surface clearly.
    #
    # Used by the parity regression spec to track XMI export fidelity
    # over time. Improvements to QeaToXmi should shrink the gaps.
    class XmiParity
      ELEMENT_TYPES = %w[
        packagedElement
        ownedAttribute
        ownedOperation
        ownedEnd
        memberEnd
        generalization
        connector
        diagram
        taggedValue
        xmi:Extension
        style
        tags
        documentation
      ].freeze

      # Per-element counts for one XMI document.
      Counts = Struct.new(:total, :by_type, keyword_init: true) do
        def initialize(*)
          super
          self.by_type ||= {}
        end

        def delta(other)
          result = { total: total - other.total }
          ELEMENT_TYPES.each do |t|
            result[t] = (by_type[t] || 0) - (other.by_type[t] || 0)
          end
          result
        end
      end

      # @param qea_path [String] path to the QEA file
      # @param reference_xmi_path [String] path to EA's reference XMI
      # @return [Hash] {:ours, :reference, :delta} each a Counts
      def self.compare(qea_path, reference_xmi_path)
        database = Ea::Qea.load(qea_path)
        ours_xml = Ea::Transformers.qea_to_xmi(database)
        ref_xml = File.read(reference_xmi_path)

        {
          qea: qea_path,
          reference: reference_xmi_path,
          ours: count(ours_xml),
          reference_counts: count(ref_xml),
          delta: count(ours_xml).delta(count(ref_xml))
        }
      end

      # @param xml [String] XMI markup (any encoding)
      # @return [Counts]
      def self.count(xml)
        # EA exports use windows-1252; force UTF-8 for safe regex.
        safe = xml.to_s.encode("UTF-8", invalid: :replace, undef: :replace,
                                replace: "?")
        by_type = ELEMENT_TYPES.each_with_object({}) do |tag, acc|
          # Match `<tag>` followed by space, `/`, or `>` (covers
          # `<tag/>`, `<tag foo=...>`, `<tag>`). Using %r{} to avoid
          # `/` regex-delimiter conflict with the `/` in the class.
          acc[tag] = safe.scan(%r{<#{tag}[\s/>]}).size
        end
        Counts.new(total: by_type.values.sum, by_type: by_type)
      end
    end
  end
end
