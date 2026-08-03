# frozen_string_literal: true

module Ea
  module Model
    # A UML InstanceSpecification — an instance of a Classifier shown
    # on an Object diagram. Carries a name, a reference to the
    # classifier it instantiates, and a list of Slots (variable =
    # value pairs parsed from EA's RunState field).
    class InstanceSpecification < Base
      attribute :name, :string
      attribute :classifier_id, :string
      attribute :classifier_name, :string
      attribute :package_id, :string
      attribute :package_name, :string
      attribute :qualified_name, :string
      attribute :slots, Slot, collection: true, initialize_empty: true
      attribute :role_name, :string
      attribute :annotations, Annotation, collection: true, initialize_empty: true

      json do
        map "id", to: :id
        map "name", to: :name
        map "classifierId", to: :classifier_id
        map "classifierName", to: :classifier_name
        map "packageId", to: :package_id
        map "packageName", to: :package_name
        map "qualifiedName", to: :qualified_name
        map "slots", to: :slots, render_empty: true
        map "roleName", to: :role_name
        map "annotations", to: :annotations, render_empty: true
      end
    end
  end
end
