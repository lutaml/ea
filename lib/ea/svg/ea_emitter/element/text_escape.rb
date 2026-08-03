# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # XML-escapes text content for safe SVG embedding.
        module TextEscape
          module_function

          def call(text)
            return "" if text.nil?

            text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub("\"", "&quot;")
          end
        end
      end
    end
  end
end
