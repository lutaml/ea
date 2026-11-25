# frozen_string_literal: true

module Ea
  module Qea
    # Canonical semantic rules shared by every QEA walker.
    #
    # The factory (→ Lutaml::Uml), the Sources adapters (→ Ea::Model)
    # and the QEA→XMI exporter each re-implemented the same EA-domain
    # mappings — visibility tokens, cardinality bounds, enumeration
    # detection — with drift between them (e.g. two Sources builders
    # silently mapped "Package" scope to public). Ea::Qea::Rules is the
    # single source for the canonical form; pipeline-specific wire
    # policies (the XMI exporter omitting the "public" default, for
    # example) layer on top in their own modules.
    module Rules
      autoload :Visibility, "ea/qea/rules/visibility"
      autoload :Cardinality, "ea/qea/rules/cardinality"
      autoload :EnumLiteral, "ea/qea/rules/enum_literal"
      autoload :Generalization, "ea/qea/rules/generalization"
    end
  end
end
