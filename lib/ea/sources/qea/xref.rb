# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Namespace for parsing EA's `t_xref.Description` mini-language.
      #
      # EA encodes semi-structured metadata in a custom format combining:
      #
      # - Stereotype application: `@STEREO;Name=X;FQName=Y;@ENDSTEREO;`
      # - Property definitions: `@PROP=@NAME=..@ENDNAME;@TYPE=..@ENDTYPE;...`
      # - Legend definitions:    `@PROP=@NAME=..;@TYPE=LEGEND_OBJECTSTYLE;...`
      # - Legacy key=value:      `aggregation=composite;direction=source;`
      #
      # The parser returns a typed `Xref::Record` value object so consumers
      # can branch on record type without re-parsing strings (OCP/MECE).
      module Xref
        autoload :Parser, "ea/sources/qea/xref/parser"
        autoload :Record, "ea/sources/qea/xref/record"
        autoload :StereotypeApplication,
                 "ea/sources/qea/xref/stereotype_application"
        autoload :PropertyDefinition, "ea/sources/qea/xref/property_definition"
        autoload :LegendDefinition, "ea/sources/qea/xref/legend_definition"
      end
    end
  end
end
