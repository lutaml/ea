# frozen_string_literal: true

module Ea
  module Rules
    # EA namespacing rule for attribute type references. Types in the
    # "core" and "gml" namespaces resolve against the classifier's own
    # upper-level package namespace; any other namespace string is
    # kept as-is; a missing namespace falls back to the upper package.
    module Namespacing
      module_function

      # @param type_ns [String, nil] attribute type namespace
      # @param upper_klass [String, nil] the classifier's upper-level
      #   package namespace
      # @return [String, nil] resolved namespace
      def resolve_name_ns(type_ns, upper_klass)
        ns = case type_ns
             when "core", "gml"
               upper_klass
             else
               type_ns
             end
        ns || upper_klass
      end
    end
  end
end
