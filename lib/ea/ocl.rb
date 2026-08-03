# frozen_string_literal: true

module Ea
  # OCL (Object Constraint Language) parser + evaluator namespace.
  # Supports a subset of OCL invariant syntax sufficient for
  # evaluating common EA constraints.
  module Ocl
    autoload :Parser, "ea/ocl/parser"
    autoload :Evaluator, "ea/ocl/evaluator"
    autoload :Nodes, "ea/ocl/nodes"
    autoload :UnsupportedError, "ea/ocl/unsupported_error"
  end
end
