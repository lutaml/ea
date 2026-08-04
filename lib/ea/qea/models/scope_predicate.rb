# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Mixin providing `public?`, `private?`, `protected?` scope
      # predicates for any model that has a `scope` attribute
      # (t_attribute.scope, t_operation.scope, t_object.scope).
      #
      # EA stores scope as a case-insensitive string ("Public",
      # "Private", "Protected"). This module centralises the
      # comparison so both EaAttribute and EaOperation share one
      # implementation.
      module ScopePredicate
        def public?
          scope&.downcase == "public"
        end

        def private?
          scope&.downcase == "private"
        end

        def protected?
          scope&.downcase == "protected"
        end
      end
    end
  end
end
