# frozen_string_literal: true

module Ea
  module Image
    # Converts EA's t_image EMF blobs to SVG strings by delegating to
    # the pure-Ruby `emfsvg` gem. Lazy-loads the gem on first call.
    #
    # When emfsvg is unavailable, returns nil — callers should fall
    # back to skipping image rendering. This keeps the gem optional
    # rather than a hard runtime requirement.
    module EmfRenderer
      module_function

      # Convert an EMF blob (raw bytes) to an SVG string.
      #
      # @param bytes [String, nil] EMF binary blob from t_image.Image
      # @param options [Hash] forwarded to Emfsvg.from_bytes
      # @return [String, nil] SVG markup, or nil if emfsvg unavailable
      def render(bytes, **options)
        return nil if bytes.nil? || bytes.empty?
        return nil unless available?

        Emfsvg.from_bytes(bytes, **options)
      rescue StandardError => e
        warn "[ea] emfsvg render failed: #{e.message}" if ENV["EA_DEBUG"]
        nil
      end

      # @return [Boolean] true if the emfsvg gem can be loaded
      def available?
        return @available if defined?(@available)

        begin
          require "emfsvg"
          @available = !!Emfsvg
        rescue LoadError
          @available = false
        end
      end
    end
  end
end
