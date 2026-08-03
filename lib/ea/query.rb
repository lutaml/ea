# frozen_string_literal: true

module Ea
  # Query DSL namespace. Provides a chainable builder for filtering
  # model elements. New predicates add new methods on the chain.
  module Query
    autoload :Builder, "ea/query/builder"
  end
end
