# frozen_string_literal: true

module Ea
  module Ocl
    # Tokenizer + parser for an OCL invariant subset. Returns an AST
    # built from Nodes::* structs.
    #
    # Supported forms:
    #   inv: <expr>
    #   self.<attr>
    #   "<literal>"
    #   <collection>->exists(x | <pred>)
    #   <collection>->forAll(x | <pred>)
    #   <string>.matches('<regex>')
    #   <expr> and <expr>
    #   <expr> or <expr>
    #   not <expr>
    module Parser
      module_function

      # @param source [String] OCL expression with optional `inv:` prefix
      # @return [Array<Nodes::*>] AST nodes (one per top-level expression)
      def parse(source)
        return [] if source.nil? || source.empty?

        body = strip_inv_prefix(source)
        parse_expression(body)
      end

      def strip_inv_prefix(source)
        s = source.strip
        s.sub(/\Ainv\s*:\s*/, "")
      end

      # Parse one expression. Returns a single AST node.
      def parse_expression(source)
        s = source.strip

        # Strip outer parens
        s = s[1..-2].strip while s.start_with?("(") && s.end_with?(")")

        # 'not <expr>'
        if s.start_with?("not ")
          return Nodes::UnaryOp.new(op: :not,
                                    operand: parse_expression(s[4..]))
        end

        # 'and' / 'or' / comparison ops — comparison has higher
        # precedence than logical, so check it first.
        if (split = split_on_comparison_op(s))
          op, left, right = split
          return Nodes::Comparison.new(op: op,
                                      left: parse_expression(left),
                                      right: parse_expression(right))
        end
        if (split = split_on_logical_op(s))
          op, left, right = split
          return Nodes::BinaryOp.new(op: op,
                                     left: parse_expression(left),
                                     right: parse_expression(right))
        end

        # Collection ->exists(...) or ->forAll(...)
        if (m = s.match(/^(.+?)->(exists|forAll)\s*\(\s*(\w+)\s*\|\s*(.+?)\s*\)\z/))
          return collection_node(m[2].to_sym, m[1], m[3], m[4])
        end

        # Collection ->size() — integer cardinality
        if (m = s.match(/^(.+?)->size\(\)\z/))
          return Nodes::CollectionSize.new(collection: parse_expression(m[1]))
        end

        # Collection ->isEmpty() — boolean
        if (m = s.match(/^(.+?)->isEmpty\(\)\z/))
          return Nodes::CollectionIsEmpty.new(collection: parse_expression(m[1]))
        end

        # String.matches('regex')
        if (m = s.match(/^(.+?)\.matches\(\s*['"](.+?)['"]\s*\)\z/))
          return Nodes::StringMatches.new(string: parse_expression(m[1]),
                                          pattern: m[2])
        end

        # Boolean literal — check BEFORE bare identifier
        return Nodes::Literal.new(value: true) if s == "true"
        return Nodes::Literal.new(value: false) if s == "false"

        # Numeric literal
        return Nodes::Literal.new(value: s.to_i) if s.match?(/\A-?\d+\z/)
        return Nodes::Literal.new(value: s.to_f) if s.match?(/\A-?\d+\.\d+\z/)

        # String literal
        return Nodes::Literal.new(value: s[1..-2]) if s.match?(/\A['"].*['"]\z/)

        # 'self.<attr>' or '<var>.<attr>' — both produce AttributeAccess.
        if (m = s.match(/\A(?:self\.|[a-z_]\w*\.)([a-z_]\w*)\z/i))
          return Nodes::AttributeAccess.new(name: m[1])
        end

        # Bare identifier — variable reference.
        if (m = s.match(/\A([a-z_]\w*)\z/))
          return Nodes::AttributeAccess.new(name: m[1])
        end

        raise UnsupportedError,
              "Unsupported OCL expression: #{source.inspect}"
      end

      def collection_node(kind, collection_src, var, pred_src)
        Nodes.const_get(kind == :exists ? :CollectionExists : :CollectionForAll)
             .new(collection: parse_expression(collection_src),
                  var: var,
                  predicate: parse_expression(pred_src))
      end

      # Find the topmost ` and ` or ` or ` outside of parens.
      # Returns [op, left_str, right_str] or nil.
      def split_on_logical_op(source)
        depth = 0
        # Look for ' or ' first (lower precedence than 'and' in OCL?)
        # Actually OCL: 'or' < 'xor' < 'and' < 'implies'. We pick the
        # rightmost top-level operator (left-associative).
        %i[and or].each do |op|
          keyword = " #{op} "
          idx = find_top_level(source, keyword)
          next unless idx

          return [op, source[0...idx], source[(idx + keyword.length)..]]
        end
        nil
      end

      # Split on top-level comparison operator (>, <, >=, <=, =, ==, !=).
      # Comparison has higher precedence than and/or, so we split here
      # BEFORE calling split_on_logical_op.
      def split_on_comparison_op(source)
        depth = 0
        %w[>= <= == != = > <].each do |op|
          # Need to be careful with `>=` vs `>`: scan in order so
          # multi-char operators are detected first.
          idx = find_top_level_op(source, op)
          next unless idx

          return [op, source[0...idx], source[(idx + op.length)..]]
        end
        nil
      end

      def find_top_level_op(source, op)
        depth = 0
        i = 0
        while i < source.length
          c = source[i]
          depth += 1 if c == "("
          depth -= 1 if c == ")"
          if depth.zero? && source[i, op.length] == op
            # Each `next` clause below MUST fall through to `i += 1`
            # at the loop's tail — using `next` here would skip the
            # increment and infinite-loop on the same matching char.
            should_skip =
              (op == ">" && source[i + 1, 1] == "=") || # >= matches as >
              (op == "<" && source[i + 1, 1] == "=") || # <= matches as <
              (op == "=" && source[i + 1, 1] == "=") || # == matches as =
              (op == ">" && source[i - 1, 1] == "-") || # -> arrow
              (op == "<" && source[i - 1, 1] == "-")   # <- arrow
            return i unless should_skip
          end
          i += 1
        end
        nil
      end

      # Find substring at depth 0 (not inside parens).
      def find_top_level(source, substring)
        depth = 0
        i = 0
        while i < source.length
          c = source[i]
          depth += 1 if c == "("
          depth -= 1 if c == ")"
          if depth.zero? && source[i, substring.length] == substring
            return i
          end
          i += 1
        end
        nil
      end
    end
  end
end
