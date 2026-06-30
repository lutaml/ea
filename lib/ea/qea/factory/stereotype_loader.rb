# frozen_string_literal: true

module Ea
  module Qea
    module Factory
      class StereotypeLoader
        def initialize(database)
          @database = database
        end

        def load_from_xref(ea_guid)
          return nil if ea_guid.nil?
          return nil unless @database.xrefs

          xref = find_stereotype_xref(ea_guid)
          return nil unless xref

          extract_stereotype_name(xref.description)
        end

        private

        def find_stereotype_xref(ea_guid)
          @database.xrefs_for_client(ea_guid).find do |x|
            x.name == "Stereotypes" && x.type == "element property"
          end
        end

        def extract_stereotype_name(description)
          return nil if description.nil? || description.empty?

          if description =~ /@STEREO;Name=([^;]+);/
            Regexp.last_match(1)
          end
        end
      end
    end
  end
end
