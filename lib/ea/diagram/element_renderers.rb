# frozen_string_literal: true

module Ea
  module Diagram
    module ElementRenderers
      autoload :BaseRenderer,
               "ea/diagram/element_renderers/base_renderer"
      autoload :ClassRenderer,
               "ea/diagram/element_renderers/class_renderer"
      autoload :PackageRenderer,
               "ea/diagram/element_renderers/package_renderer"
      autoload :ConnectorRenderer,
               "ea/diagram/element_renderers/connector_renderer"

      # Registry for element type to renderer class mapping.
      # New element types can be added without modifying SvgRenderer.
      class RendererRegistry
        def initialize
          @renderers = {}
        end

        def register(element_type, renderer_class)
          @renderers[element_type.to_s] = renderer_class
        end

        def renderer_for(element_type)
          @renderers[element_type.to_s]
        end

        def registered?(element_type)
          @renderers.key?(element_type.to_s)
        end
      end

      # Default registry with built-in renderers
      DEFAULT_REGISTRY = RendererRegistry.new.tap do |r|
        r.register("class", ClassRenderer)
        r.register("datatype", ClassRenderer)
        r.register("package", PackageRenderer)
      end
    end
  end
end
