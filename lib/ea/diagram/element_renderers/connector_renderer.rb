# frozen_string_literal: true

module Ea
  module Diagram
    module ElementRenderers
      # Renderer for connector elements (relationships)
      class ConnectorRenderer < BaseRenderer
        attr_reader :source_element, :target_element

        def initialize(connector, style_resolver, source_element = nil,
                       target_element = nil)
          super(connector, style_resolver)
          @source_element = source_element
          @target_element = target_element
        end

        # Render the connector as SVG path
        # @return [String] SVG content for the connector
        def render
          path_builder = PathBuilder.new(element, source_element,
                                         target_element)
          path_data = path_builder.build_path

          style = style_resolver.resolve_connector_style(element)

          css_classes = ["lutaml-diagram-connector",
                         "lutaml-diagram-connector-#{element[:type]}"]

          <<~SVG
            <path d="#{path_data}"
                  class="#{css_classes.join(' ')}"
                  style="#{style_to_css(style)}"
                  data-connector-id="#{element[:id]}"
                  data-connector-type="#{element[:type]}"
                  marker-end="url(#arrowhead)" />
          SVG
        end
      end
    end
  end
end
