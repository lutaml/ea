# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Open-closed dispatcher: maps a Sparx element-kind key to the emitter
      # that handles it. New kinds are added by calling {.register} from a
      # new emitter file — no edits to existing dispatch code.
      class EmitterRegistry
        @registry = {}

        class << self
          # @param key [Symbol] sparx kind, e.g. :package, :class, :association
          # @param emitter [#emit] instance responding to `#emit(record, ctx)`
          # @return [void]
          def register(key, emitter)
            @registry[key.to_sym] = emitter
          end

          # @param key [Symbol]
          # @return [#emit, nil] the registered emitter, or nil if none
          def for?(key)
            @registry[key.to_sym]
          end

          # @param key [Symbol]
          # @return [#emit]
          # @raise [ArgumentError] if no emitter is registered for `key`
          def for(key)
            @registry[key.to_sym] ||
              raise(ArgumentError, "No emitter registered for #{key.inspect}")
          end

          # @return [Array<Symbol>] all registered keys
          def registered_keys
            @registry.keys
          end

          # Test-only: removes a key. Production code never unregisters.
          # @param key [Symbol]
          # @return [void]
          def delete(key)
            @registry.delete(key.to_sym)
          end
        end
      end
    end
  end
end
