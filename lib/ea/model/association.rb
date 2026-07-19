# frozen_string_literal: true

module Ea
  module Model
    # An Association between two classifiers. Each end carries its
    # own role name, multiplicity, aggregation kind, and
    # navigability. Source and target are referenced by id.
    class Association < Relationship
      attribute :source_id, :string
      attribute :target_id, :string
      attribute :source_role_name, :string
      attribute :target_role_name, :string
      attribute :source_multiplicity_lower, :integer
      attribute :source_multiplicity_upper, :integer
      attribute :target_multiplicity_lower, :integer
      attribute :target_multiplicity_upper, :integer
      attribute :source_aggregation, :string, default: -> { "none" }
      attribute :target_aggregation, :string, default: -> { "none" }
      attribute :source_navigable, :boolean, default: true
      attribute :target_navigable, :boolean, default: true

      attribute :relationship_kind, :string, default: -> { "association" }

      json do
        map "sourceId", to: :source_id
        map "targetId", to: :target_id
        map "sourceRoleName", to: :source_role_name
        map "targetRoleName", to: :target_role_name
        map "sourceMultiplicityLower", to: :source_multiplicity_lower
        map "sourceMultiplicityUpper", to: :source_multiplicity_upper
        map "targetMultiplicityLower", to: :target_multiplicity_lower
        map "targetMultiplicityUpper", to: :target_multiplicity_upper
        map "sourceAggregation", to: :source_aggregation, render_default: true
        map "targetAggregation", to: :target_aggregation, render_default: true
        map "sourceNavigable", to: :source_navigable, render_default: true
        map "targetNavigable", to: :target_navigable, render_default: true
      end
    end
  end
end
