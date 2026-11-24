# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      module Xref
        # Stereotype application record. Produced when the Description
        # starts with `@STEREO;`. Captures the short name and the
        # fully-qualified `tech::Stereo` form when present.
        #
        # Example source:
        #   @STEREO;Name=FeatureType;FQName=GML::FeatureType;@ENDSTEREO;
        StereotypeApplication = Struct.new(:name, :fqname, keyword_init: true) do
          # Returns the technology prefix from FQName, or nil.
          # @return [String, nil]
          def technology
            return nil unless fqname

            idx = fqname.index("::")
            idx ? fqname[0, idx] : nil
          end

          # Returns the stereotype name without technology prefix.
          # Falls back to +name+ when FQName is absent.
          # @return [String, nil]
          def unqualified_name
            if fqname && fqname.include?("::")
              fqname.split("::", 2).last
            else
              name
            end
          end
        end
      end
    end
  end
end
