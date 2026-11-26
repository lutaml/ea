# frozen_string_literal: true

module Ea
  module Rules
    # Shared construction of Lutaml::Uml::GeneralAttribute rows for
    # both the QEA factory and the XMI parser — one place for the
    # field list and the boolean coercions (is_derived normalizes
    # boolean-or-nil, has_association mirrors the presence of an
    # association reference). The definition is taken verbatim: each
    # walker resolves and strips it according to its own source
    # semantics.
    module GeneralAttributeMapping
      module_function

      # @param fields [Hash] :id, :name, :type, :xmi_id, :cardinality,
      #   :definition, :association, :type_ns, :is_derived
      # @return [Lutaml::Uml::GeneralAttribute]
      def build(fields)
        association = fields[:association]
        Lutaml::Uml::GeneralAttribute.new(
          id: fields[:id],
          name: fields[:name],
          type: fields[:type],
          xmi_id: fields[:xmi_id],
          cardinality: fields[:cardinality],
          definition: fields[:definition],
          association: association,
          type_ns: fields[:type_ns],
          is_derived: fields[:is_derived] == true,
          has_association: !association.nil?
        )
      end
    end
  end
end
