# frozen_string_literal: true

module Ea
  module Ocl
    # AST node types for the parser. Each is a small Struct that the
    # Evaluator dispatches on by class.
    module Nodes
      # `self.<attr>` access — read attribute on the context object.
      AttributeAccess = Struct.new(:name, keyword_init: true)

      # Literal value (number, string, boolean).
      Literal = Struct.new(:value, keyword_init: true)

      # `<collection>->exists(var | <pred>)` — true if any element matches.
      CollectionExists = Struct.new(:collection, :var, :predicate,
                                    keyword_init: true)

      # `<collection>->forAll(var | <pred>)` — true if all match.
      CollectionForAll = Struct.new(:collection, :var, :predicate,
                                    keyword_init: true)

      # `<string>.matches('<regex>')`
      StringMatches = Struct.new(:string, :pattern, keyword_init: true)

      # `<a> and <b>`, `<a> or <b>`, `not <a>`
      BinaryOp = Struct.new(:op, :left, :right, keyword_init: true)
      UnaryOp = Struct.new(:op, :operand, keyword_init: true)

      # `<collection>->size()` — returns integer cardinality.
      CollectionSize = Struct.new(:collection, keyword_init: true)

      # `<collection>->isEmpty()` — returns boolean.
      CollectionIsEmpty = Struct.new(:collection, keyword_init: true)

      # `<a> op <b>` where op ∈ {>, <, >=, <=, =, ==, !=}.
      Comparison = Struct.new(:op, :left, :right, keyword_init: true)
    end
  end
end
