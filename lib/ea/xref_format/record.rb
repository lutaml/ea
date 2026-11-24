# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      module Xref
        # Parsed t_xref.Description. Holds typed records for each block
        # found in the source string. One Description can carry multiple
        # records (e.g., several `@PROP=` blocks defining a stereotype's
        # tagged-value set).
        #
        # Consumers branch on record type without re-parsing strings.
        Record = Struct.new(:stereotype, :properties, :legends,
                            :key_values, :raw, keyword_init: true) do
          def initialize(*)
            super
            self.properties ||= []
            self.legends ||= []
            self.key_values ||= {}
          end

          # @return [Boolean] true when a stereotype application is present
          def stereotype?
            !stereotype.nil?
          end

          # @return [Boolean] true when at least one legend is present
          def legend?
            !legends.empty?
          end

          # Convenience: first legend's name (the legend's title).
          # @return [String, nil]
          def legend_title
            legends.first&.name
          end
        end
      end
    end
  end
end
