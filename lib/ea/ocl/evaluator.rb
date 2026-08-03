# frozen_string_literal: true

module Ea
  module Ocl
    # Evaluates an AST produced by Parser against a context object
    # (the model element under test). Dispatches on node class.
    module Evaluator
      module_function

      # @param ast [Nodes::*]
      # @param context [Object] the model element (self)
      # @return [Boolean, Object] result of evaluation
      def evaluate(ast, context)
        case ast
        when Nodes::Literal then ast.value
        when Nodes::AttributeAccess then attribute_value(context, ast.name)
        when Nodes::StringMatches then eval_string_matches(ast, context)
        when Nodes::CollectionExists then eval_exists(ast, context)
        when Nodes::CollectionForAll then eval_for_all(ast, context)
        when Nodes::BinaryOp then eval_binary(ast, context)
        when Nodes::UnaryOp then eval_unary(ast, context)
        else
          raise UnsupportedError,
                "Cannot evaluate AST node: #{ast.class}"
        end
      end

      def attribute_value(context, name)
        return nil unless context

        context.public_send(name)
      end

      def eval_string_matches(ast, context)
        target = evaluate(ast.string, context).to_s
        Regexp.new(ast.pattern).match?(target)
      end

      def eval_exists(ast, context)
        collection = evaluate(ast.collection, context)
        return false unless collection.is_a?(Array)

        var_name = ast.var
        predicate = ast.predicate
        collection.any? do |element|
          evaluate(predicate, var_binding(context, var_name, element))
        end
      end

      def eval_for_all(ast, context)
        collection = evaluate(ast.collection, context)
        return true unless collection.is_a?(Array)

        var_name = ast.var
        predicate = ast.predicate
        collection.all? do |element|
          evaluate(predicate, var_binding(context, var_name, element))
        end
      end

      def eval_binary(ast, context)
        left = evaluate(ast.left, context)
        right = evaluate(ast.right, context)
        case ast.op
        when :and then left && right
        when :or then left || right
        else raise UnsupportedError, "Unknown binary op: #{ast.op}"
        end
      end

      def eval_unary(ast, context)
        case ast.op
        when :not then !evaluate(ast.operand, context)
        else raise UnsupportedError, "Unknown unary op: #{ast.op}"
        end
      end

      # Bind a variable name in the evaluation context. Uses a small
      # Struct wrapper so attribute lookups still fall through to the
      # original context.
      VarBinding = Struct.new(:context, :var_name, :value, keyword_init: true) do
        def public_send(method_name, *args)
          return value if method_name == var_name

          context.public_send(method_name, *args)
        end
      end

      def var_binding(context, var_name, value)
        VarBinding.new(context: context, var_name: var_name, value: value)
      end
    end
  end
end
