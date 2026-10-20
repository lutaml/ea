# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Builds an `Ea::Model::Legend` from the `value` of an element's
      # `<xrefs>` element. The CustomProperties description inside it
      # uses the same `@PROP=...@ENDPROP;` encoding as the QEA t_xref
      # row, so parsing is delegated to the QEA legend builder.
      #
      # Returns nil when the value carries no legend properties.
      class LegendBuilder
        CLIENT = "xmi-element"

        XrefRow = Struct.new(:name, :description)

        # Answers the one CustomProperties xref lookup the QEA builder makes.
        class SingleElementXrefs
          def initialize(description)
            @rows = [XrefRow.new(Qea::LegendBuilder::LEGEND_XREF_NAME, description)]
          end

          def xrefs_for_client(_guid)
            @rows
          end
        end

        def initialize(xrefs_value)
          @xrefs_value = xrefs_value
        end

        def build
          return nil if @xrefs_value.to_s.empty?

          Qea::LegendBuilder.new(SingleElementXrefs.new(@xrefs_value)).build_for(CLIENT)
        end
      end
    end
  end
end
