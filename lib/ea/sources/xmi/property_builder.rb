# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Translates XMI OwnedAttribute elements into Ea::Model::Property
      # instances. Multiplicity comes from lower_value / upper_value
      # (LiteralInteger / LiteralUnlimitedNatural polymorphic
      # children).
      class PropertyBuilder
        def build_all_for(classifier)
          classifier.owned_attribute.map { |attr| build_one(attr, classifier) }
        end

        def build_one(attr, owner)
          id = IdNormalizer.from_xmi_id(attr.id) ||
               IdNormalizer.synthetic_id(owner.id, "attr", attr.name)
          Ea::Model::Property.new(
            id: id,
            name: attr.name,
            owner_id: owner.id,
            type_name: type_name_for(attr),
            qualified_name: "#{owner.name}::#{attr.name}",
            multiplicity_lower: parse_lower(attr),
            multiplicity_upper: parse_upper(attr),
            default_value: default_value_for(attr),
            is_derived: boolean(attr.is_derived),
            is_readonly: boolean(attr.is_read_only),
            is_ordered: boolean(attr.is_ordered),
            is_unique: boolean(attr.is_unique),
            aggregation: attr.aggregation || "none",
            visibility: attr.visibility,
            annotations: AnnotationBuilder.from_element(attr, id)
          )
        end

        private

        def type_name_for(attr)
          # OwnedAttribute#type is the xmi:type discriminator
          # (e.g. "uml:Property"); the actual data type reference is
          # on the child <type xmi:idref=...> element, exposed via
          # uml_type.idref.
          attr.uml_type&.idref
        end

        def parse_lower(attr)
          value = attr.lower_value
          return 1 unless value

          Integer(value.value) rescue 1
        end

        def parse_upper(attr)
          value = attr.upper_value
          return 1 unless value

          raw = value.value
          return -1 if raw.to_s == "*"

          Integer(raw) rescue 1
        end

        def default_value_for(attr)
          attr.default_value&.value
        end

        def boolean(value)
          case value
          when true, "true" then true
          else false
          end
        end
      end
    end
  end
end
