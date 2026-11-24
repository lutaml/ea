# frozen_string_literal: true

module Ea
  # Shared parser for EA's `t_xref.Description` mini-language — the
  # canonical converter for `@STEREO`/`@PROP`/key-value description
  # blocks (house style alongside GuidFormat, Rtf, XmlEscape).
  #
  # Lives at the top level so the QEA model layer can use it without
  # reaching up into the Sources adapter layer. Consumers:
  # Ea::Qea::Models::EaXref, Ea::Query::Builder, Ea::Lint stereotype
  # rules, Ea::Qea::Factory::StereotypeLoader, and the Sources
  # diagram builders.
  module XrefFormat
    autoload :Parser, "ea/xref_format/parser"
    autoload :Record, "ea/xref_format/record"
    autoload :StereotypeApplication, "ea/xref_format/stereotype_application"
    autoload :PropertyDefinition, "ea/xref_format/property_definition"
    autoload :LegendDefinition, "ea/xref_format/legend_definition"

    module_function

    # The `Name` field of the first `@STEREO;...;` application in the
    # description, or nil. Handles both the legacy
    # `@STEREO;Name=X;GUID={..};` and plateau `@STEREO;Name=X;FQName=Y;`
    # forms; unqualified for FQName-carrying applications.
    # @param description [String, nil]
    # @return [String, nil]
    def stereotype_name(description)
      return nil if description.nil? || description.empty?
      return nil unless description.include?("@STEREO")

      application = Parser.parse(description).stereotype
      application&.unqualified_name
    end
  end
end
