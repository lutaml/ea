# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Marker
        # Dispatches a connector to the first registered Kind that
        # handles its effective type. New kinds are added by calling
        # `Registry.register(MyKind)` — no modification of existing
        # code required (OCP).
        class Registry
          @kinds = []

          class << self
            attr_reader :kinds

            def register(kind)
              @kinds << kind
            end

            def specs_for(connector, effective_type, source, target,
                          before_target, after_source, relationship: nil)
              # Lazy: ensure built-in markers are registered on first
              # query. The Marker module's autoload declaration means
              # the marker files only load when referenced.
              Marker.ensure_builtins_registered! if defined?(Marker)
              kind = @kinds.find { |k| k.handles?(effective_type) }
              return [] unless kind

              kind.specs_for(connector, source, target, before_target,
                             after_source, relationship: relationship)
            end
          end

          # Spec carries the geometry recipe for a single marker
          # emission. Renderers consume it.
          Spec = Struct.new(:shape, :anchor, :base, keyword_init: true)
        end
      end
    end
  end
end
