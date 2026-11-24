# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      module Xref
        # Tagged-value / property definition record. Produced when the
        # Description contains one or more `@PROP=@NAME=..@ENDNAME;`
        # blocks for non-legend properties.
        #
        # Example source:
        #   @PROP=@NAME=isActive@ENDNAME;@TYPE=Boolean@ENDTYPE;
        #         @VALU=@ENDVALU;@PRMT=@ENDPRMT;@ENDPROP;
        PropertyDefinition = Struct.new(:name, :type, :value, :parameter,
                                        keyword_init: true) do
          # @return [Boolean] true when the value field is non-empty
          def default_value?
            !value.nil? && !value.empty?
          end

          # @return [Boolean] true when the property is declared as Boolean
          def boolean?
            type == "Boolean"
          end
        end
      end
    end
  end
end
