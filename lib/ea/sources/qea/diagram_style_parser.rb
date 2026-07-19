# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Parses EA's packed `objectstyle` / `style` / `styleex`
      # strings into a Hash with typed keys. EA packs visual style
      # as `DUID=...;BCol=...;FCol=...;` etc. — semicolon-separated
      # key=value pairs with non-standard escaping.
      module DiagramStyleParser
        module_function

        def parse(style_string)
          return {} if style_string.nil? || style_string.empty?

          style_string.to_s
                      .split(";")
                      .filter_map { |pair| parse_pair(pair) }
                      .to_h
        end

        def parse_pair(pair)
          return nil unless pair.include?("=")

          key, value = pair.split("=", 2)
          return nil if key.nil? || key.empty?

          [normalize_key(key), normalize_value(value)]
        end

        def normalize_key(key)
          key.strip.downcase.to_sym
        end

        def normalize_value(value)
          return "" if value.nil?

          value.strip
        end
      end
    end
  end
end
