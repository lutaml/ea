# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Lightweight value object returned by `Transformer#build_association_end`.
      #
      # Carries both the synthesised xmi:id of the `<ownedEnd>` element
      # (used to populate `<memberEnd idref="...">` on the enclosing
      # `<packagedElement xmi:type="uml:Association">`) and the model
      # instance itself.
      #
      # Using a Struct (not a Hash) makes the contract visible at the
      # call site: typos like `end.xmii_id` raise NoMethodError instead
      # of silently returning nil.
      AssociationEnd = Struct.new(:xmi_id, :model)
    end
  end
end
