# frozen_string_literal: true

module Ea
  module Qea
    module Rules
      # Enumeration detection: an EA object is an enumeration either by
      # its t_object.Object_Type ("Enumeration") or by carrying the
      # `enumeration` stereotype.
      module EnumLiteral
        module_function

        # @param object_type [String, nil] t_object.Object_Type
        # @param stereotype [String, nil] the object's stereotype
        # @return [Boolean]
        def enumeration?(object_type, stereotype)
          object_type == "Enumeration" ||
            stereotype.to_s.downcase == "enumeration"
        end
      end
    end
  end
end
