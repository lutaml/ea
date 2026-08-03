# frozen_string_literal: true

module Ea
  module Shapescript
    # Tokenizer + parser for ShapeScript. Returns a list of Shape
    # primitives extracted from a single shape body.
    #
    # Supported grammar (extended):
    #
    #   script        := statement*
    #   statement     := shape | var_decl | primitive | if_stmt | label
    #   shape         := "shape" identifier "{" statement* "}"
    #   var_decl      := "var" identifier "=" expr ";"
    #   primitive     := call "(" args ")" ";"
    #   call          := "rectangle" | "ellipse" | "polygon" |
    #                    "line" | "path" | "label"
    #   args          := expr ("," expr)*
    #   if_stmt       := "if" "(" expr ")" "{" statement* "}"
    #                    ("else" "{" statement* "}")?
    #   expr          := identifier | number | string | binop
    #
    # Variables are resolved at parse time when possible; otherwise
    # the identifier is left as a string for late binding.
    module Parser
      module_function

      # @param source [String] ShapeScript source
      # @return [Array<Shape>] flat list of all primitives across
      #   all shapes in the source. Shape nesting is flattened.
      #   Variables, conditionals, and labels are resolved/inlined
      #   where possible; unresolvable expressions are skipped.
      def parse(source)
        return [] if source.nil? || source.empty?

        tokens = tokenize(source)
        env = {}
        shapes = []
        consume_statements(tokens, env, shapes)
        shapes
      end

      # -- Tokenizer ---------------------------------------------------

      def tokenize(source)
        clean = source.gsub(%r{//[^\n]*}, "")
                      .gsub(/\/\*.*?\*\//m, "")
        clean.scan(/[A-Za-z_][A-Za-z0-9_]*|-?\d+\.?\d*|"[^"]*"|'[^']*'|[{}(),;=+\-*\/]/)
      end

      # Consume statements until matching close brace or end.
      def consume_statements(tokens, env, shapes, top_level: true)
        until tokens.empty?
          tok = tokens.first
          if tok == "}"
            tokens.shift if top_level == false
            break
          end

          tokens.shift # consume tok
          case tok
          when "shape"
            _name = tokens.shift
            _open = tokens.shift # "{"
            consume_statements(tokens, env.dup, shapes, top_level: false)
          when "var"
            consume_var_decl(tokens, env)
          when "if"
            consume_if(tokens, env, shapes)
          when "label"
            shapes << consume_label(tokens, env)
          else
            shapes << consume_primitive(tok, tokens, env) if PRIMITIVES.key?(tok)
          end
        end
      end

      PRIMITIVES = {
        "rectangle" => :rectangle,
        "ellipse" => :ellipse,
        "polygon" => :polygon,
        "line" => :line,
        "path" => :path
      }.freeze

      def consume_primitive(name, tokens, env)
        kind = PRIMITIVES[name]
        open_paren = tokens.shift # "("
        params = []
        if open_paren == "("
          until tokens.empty?
            tok = tokens.shift
            break if tok == ")"

            value = resolve_expr(tok, tokens, env)
            params << value if value.is_a?(Numeric)
          end
        end
        consume_semicolon(tokens)
        Shape.new(kind: kind, params: params)
      end

      def consume_label(tokens, env)
        tokens.shift # "("
        text = tokens.shift
        text = text.to_s.gsub(/\A["']|["']\z/, "")
        tokens.shift until tokens.empty? || tokens.first == ")"
        tokens.shift # ")"
        consume_semicolon(tokens)
        Shape.new(kind: :label, params: [text])
      end

      def consume_var_decl(tokens, env)
        name = tokens.shift
        eq = tokens.shift # "="
        value = resolve_expr(tokens.shift, tokens, env)
        consume_semicolon(tokens)
        env[name] = value if value.is_a?(Numeric) || value.is_a?(String)
      end

      def consume_if(tokens, env, then_shapes)
        tokens.shift # "("
        condition = resolve_expr(tokens.shift, tokens, env)
        tokens.shift until tokens.empty? || tokens.first == ")"
        tokens.shift # ")"
        tokens.shift # "{"

        # Evaluate condition; if true, consume then-block into shapes.
        # If false, skip then-block and consume optional else.
        truthy = condition == true || (condition.is_a?(Numeric) && condition.nonzero?)
        if truthy
          consume_statements(tokens, env, then_shapes, top_level: false)
        else
          skip_block(tokens)
          if tokens.first == "else"
            tokens.shift
            tokens.shift # "{"
            consume_statements(tokens, env, then_shapes, top_level: false)
          end
        end
      end

      def skip_block(tokens)
        tokens.shift # "{"
        depth = 1
        until tokens.empty? || depth.zero?
          t = tokens.shift
          depth += 1 if t == "{"
          depth -= 1 if t == "}"
        end
      end

      def consume_semicolon(tokens)
        tokens.shift if tokens.first == ";"
      end

      # Resolve an expression to a value. Returns Numeric/String/Boolean
      # or nil when unresolvable. Handles simple binary ops (+, -, *, /).
      def resolve_expr(tok, tokens, env)
        return nil unless tok

        # Parenthesized sub-expression
        if tok == "("
          value = resolve_expr(tokens.shift, tokens, env)
          tokens.shift if tokens.first == ")"
          return value
        end

        # Numeric literal
        return tok.to_i if tok.match?(/\A-?\d+\z/)
        return tok.to_f if tok.match?(/\A-?\d+\.\d+\z/)

        # String literal
        return tok[1..-2] if tok.match?(/\A["'].*["']\z/)

        # Boolean literals
        return true if tok == "true"
        return false if tok == "false"

        # Variable reference
        if env.key?(tok)
          value = env[tok]
          # Look ahead for binary op
          if %w[+ - * /].include?(tokens.first)
            op = tokens.shift
            rhs = resolve_expr(tokens.shift, tokens, env)
            return apply_binop(op, value, rhs)
          end
          return value
        end

        # Bare identifier (function call? hasproperty? — leave as nil
        # for now; treat as false in conditionals).
        nil
      end

      def apply_binop(op, left, right)
        return nil unless left.is_a?(Numeric) && right.is_a?(Numeric)

        case op
        when "+" then left + right
        when "-" then left - right
        when "*" then left * right
        when "/" then left / right
        end
      end
    end
  end
end
