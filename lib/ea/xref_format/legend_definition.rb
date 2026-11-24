# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      module Xref
        # Legend definition record. Produced when the Description contains
        # `@PROP=` blocks with `@TYPE=LEGEND_*`. EA encodes legend
        # entries as color/style rules keyed by name.
        #
        # Example source:
        #   @PROP=@NAME=GMLに定義されたクラス@ENDNAME;
        #         @TYPE=LEGEND_OBJECTSTYLE@ENDTYPE;
        #         @VALU=#Back_Ground_Color#=13434828;#Pen_Color#=0;
        #               #Pen_Size#=1;#Legend_Type#=LEGEND_OBJECTSTYLE;
        #               @ENDVALU;@PRMT=0@ENDPRMT;@ENDPROP;
        LegendDefinition = Struct.new(:name, :legend_type, :colors,
                                      :parameter, keyword_init: true) do
          # EA encodes colors as signed 32-bit integers (VB-style).
          # Convert to `#RRGGBB` hex string for SVG consumption.
          # @param key [Symbol] color key, e.g. :back_ground_color
          # @return [String, nil] hex color (`#RRGGBB`) or nil
          def hex_color(key)
            value = colors&.dig(key)
            return nil if value.nil?

            int = value.to_i
            int = (int + 2**32) % 2**32 if int.negative?
            format("#%06X", int & 0xFFFFFF)
          end
        end
      end
    end
  end
end
