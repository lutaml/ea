# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      class DiagramBuilder
        # Keep graphical spelling provenance separate from semantic stereotype names.
        class StereotypeProfiles
          def initialize(root)
            @elements = root.extension&.elements&.element.to_a.to_h { |element| [element.idref, element] }
          end

          def for(subject)
            element = @elements[subject]
            name = element&.properties&.stereotype
            return {} if name.to_s.empty?

            fqname = matching_profile(element.xrefs&.value.to_s, name)
            fqname ? { stereotype_fqname: fqname } : {}
          end

          private

          def matching_profile(value, name)
            value.split("@STEREO;").drop(1).each do |block|
              description = "@STEREO;#{block.partition("@ENDSTEREO;").first}@ENDSTEREO;"
              application = Qea::Xref::Parser.parse(description).stereotype
              return application.fqname if application.name == name
            end
            nil
          end
        end
      end
    end
  end
end
