# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Pure conversions between Sparx EA GUID strings and XMI identifier
      # strings. No state, no I/O — same input always yields same output.
      #
      # EA stores identifiers as `{ABCD-1234-...}` braced GUID strings. XMI
      # serializations use unbraced, dash→underscore forms prefixed with
      # `EAID_` (most elements) or `EAPK_` (packages at the model root).
      module GuidFormat
        # Braces and dashes both become underscores; collapse runs of
        # consecutive underscores so `{AB-CD}` → `AB_CD` (not `_AB_CD_`).
        SEP = /[-{}]/

        module_function

        # @param ea_guid [String, nil] e.g. "{AB-CD-EF}"
        # @param prefix [String] "EAID" (default) or "EAPK"
        # @return [String, nil] e.g. "EAID_AB_CD_EF"
        def ea_guid_to_xmi_id(ea_guid, prefix: "EAID")
          return nil if ea_guid.nil? || ea_guid.empty?

          clean = ea_guid.gsub(SEP, "_").gsub(/_+/, "_").gsub(/\A_/, "").gsub(/_\z/, "")
          "#{prefix}_#{clean}"
        end

        # @param xmi_id [String, nil] e.g. "EAID_AB_CD_EF"
        # @return [String, nil] e.g. "{AB-CD-EF}"
        def xmi_id_to_ea_guid(xmi_id)
          return nil if xmi_id.nil? || xmi_id.empty?

          body = xmi_id.sub(/\A(?:EAID|EAPK)_/, "")
          "{#{body.tr('_', '-')}}"
        end

        # Build a member-end xmi:id for one side of a connector.
        #
        # Sparx EA's convention: take the connector's GUID, drop the first two
        # hex characters of its first segment, and prepend `src` or `dst`.
        #
        # @param connector_xmi_id [String] e.g. "EAID_AB12CDEF_..."
        # @param side [Symbol] :source or :destination
        # @return [String] e.g. "EAID_src2CDEF_..."
        def connector_end_xmi_id(connector_xmi_id, side:)
          tag = side == :source ? "src" : "dst"
          body = connector_xmi_id.sub(/\A(?:EAID|EAPK)_/, "")
          first_segment, rest = body.split("_", 2)
          trimmed = first_segment.length > 2 ? first_segment[2..] : first_segment
          rest ? "EAID_#{tag}#{trimmed}_#{rest}" : "EAID_#{tag}#{trimmed}"
        end
      end
    end
  end
end
