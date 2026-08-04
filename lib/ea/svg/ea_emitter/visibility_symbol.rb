# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Maps UML visibility strings to EA's single-character symbols.
      #
      # Centralised so that adding a new visibility level (e.g.
      # "implementation" in Java) changes one hash entry, not three
      # case/when branches across separate renderer files.
      #
      # EA's convention:
      #   +  public
      #   -  private
      #   #  protected
      #   ~  package
      module VisibilitySymbol
        SYMBOLS = {
          "public" => "+",
          "private" => "-",
          "protected" => "#",
          "package" => "~"
        }.freeze

        # @param visibility [String, nil] EA scope string ("Public",
        #   "Private", etc.). Case-insensitive; nil defaults to public.
        # @param with_space [Boolean] append a trailing space (used
        #   by operation renderers: "+ method", not "+method").
        # @return [String] the UML visibility symbol
        def self.for(visibility, with_space: false)
          symbol = SYMBOLS[(visibility || "public").downcase] || "+"
          with_space ? "#{symbol} " : symbol
        end
      end
    end
  end
end
