# frozen_string_literal: true

require "strscan"

module Ea
  module Transformers
    module QeaToXmi
      # Pure-function parser for EA's RunState column on `t_object`.
      #
      # EA serialises instance-specification run-state as a delimited
      # string of the form:
      #
      #   @VAR;Variable=<name>;Value=<value>;Op=<op>;@ENDVAR;
      #
      # Multiple variables concatenate directly:
      #
      #   @VAR;Variable=a;Value=1;Op==;@ENDVAR;@VAR;Variable=b;Value=2;Op==;@ENDVAR;
      #
      # Each `@VAR ... @ENDVAR;` block maps to one UML Slot. The
      # `Variable` is the attribute name on the classifier (used to
      # resolve the definingFeature EAID at transformation time).
      # The `Value` plus `Op` form the OpaqueExpression body — Sparx
      # prepends the operator character to the value (`Op==` →
      # `body="=Value"`).
      #
      # The parser is pure: no I/O, no state. Same input always yields
      # the same output array of {Variable, Value, Op} structs.
      module RunState
        # A single parsed RunState variable binding.
        #
        # @!attribute variable [String] the attribute name on the classifier
        # @!attribute value [String] the literal value text
        # @!attribute op [String] the operator character(s) EA stored
        Binding = Struct.new(:variable, :value, :op) do
          # Sparx serialises the value with the operator character
          # prepended (`Op==` → `body="=Value"`). For other operators
          # (`!=`, `<`, `>`) the full operator string is prepended.
          #
          # @return [String] the body to set on the OpaqueExpression
          def body
            return value if op.nil? || op.empty?

            "#{op[0]}#{value}"
          end
        end

        module_function

        # @param raw [String, nil] the EA RunState column content
        # @return [Array<Binding>] one Binding per @VAR block; empty
        #   array for nil/empty/blank input.
        def parse(raw)
          return [] if raw.nil? || raw.to_s.strip.empty?

          stripped = raw.to_s
          each_var_block(stripped).map do |block|
            parse_binding(block)
          end
        end

        # ---- Internal helpers ----

        # Yields each `@VAR;...;@ENDVAR;` block body (without the
        # delimiters). Tolerant of multiple blocks concatenated
        # without separation.
        def each_var_block(raw)
          return enum_for(:each_var_block, raw) unless block_given?

          scanner = StringScanner.new(raw)
          until scanner.eos?
            scanner.scan_until(/@VAR;/) || break
            body = scanner.scan_until(/@ENDVAR;/)
            break if body.nil?

            yield body.sub(/@ENDVAR;\z/, "")
          end
        end

        # @param block [String] the inside of one @VAR;...;@ENDVAR;
        #   block, e.g. `Variable=a;Value=1;Op==;`
        # @return [Binding]
        def parse_binding(block)
          fields = parse_fields(block)
          Binding.new(
            fields["Variable"] || "",
            fields["Value"] || "",
            fields["Op"] || "",
          )
        end

        # Parse `Key=value;` pairs into a Hash. Values may contain
        # `;` literally — only split on `;` immediately followed by a
        # known key boundary. In practice EA's values rarely contain
        # semicolons, so a simple split is sufficient.
        #
        # @param block [String]
        # @return [Hash{String=>String}]
        def parse_fields(block)
          block.split(";").each_with_object({}) do |pair, hash|
            key, value = pair.split("=", 2)
            hash[key] = value.to_s if key && !key.empty?
          end
        end
      end
    end
  end
end
