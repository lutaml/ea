# frozen_string_literal: true

module Ea
  # Shared XML entity escaping. Centralised so the four subsystems
  # that emit XML/XMI/SVG (Transformers, Diff, Shapescript, Svg)
  # share one implementation instead of four local copies with
  # subtle differences (quote-escaping was inconsistent).
  module XmlEscape
    module_function

    # @param text [Object] value to escape; nil-safe via to_s
    # @return [String] XML-escaped text with &, <, >, " replaced
    def call(text)
      text.to_s
          .gsub("&", "&amp;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
          .gsub('"', "&quot;")
    end
  end
end
