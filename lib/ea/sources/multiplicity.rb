# frozen_string_literal: true

module Ea
  module Sources
    # Multiplicity-string parsing shared by the QEA and XMI source
    # adapters. EA multiplicity text is "lower..upper", "*" meaning
    # unbounded (parsed as -1); blank or absent text means the
    # multiplicity was never specified (parsed as nil, which renderers
    # use to suppress the label).
    module Multiplicity
      module_function

      # @param cardinality [String, nil] raw multiplicity text
      # @return [Integer, nil] lower bound, or nil when unspecified
      def lower(cardinality)
        text = raw(cardinality)
        return nil unless text

        Integer(text.split("..").first, exception: false)
      end

      # @param cardinality [String, nil] raw multiplicity text
      # @return [Integer, nil] upper bound (-1 unbounded),
      #   or nil when unspecified
      def upper(cardinality)
        text = raw(cardinality)
        return nil unless text

        up = text.split("..").last
        up == "*" ? -1 : Integer(up, exception: false)
      end

      # @param cardinality [Object] raw value from the source
      # @return [String, nil] stripped text, nil when blank
      def raw(cardinality)
        text = cardinality.to_s.strip
        text.empty? ? nil : text
      end
    end
  end
end
