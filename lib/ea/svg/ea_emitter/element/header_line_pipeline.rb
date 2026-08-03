# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # OCP-friendly header line pipeline. Each contributor is a
        # stateless provider that appends 0+ lines to the output.
        # New behaviors add a new provider to PROVIDERS without
        # modifying existing ones.
        #
        # Context (Struct) carries everything a provider might need:
        #   classifier, diagram_package_id, visually_nested,
        #   umldi_keyword, bounds_width, font_size,
        #   off_canvas_parent_name
        #
        # Each provider implements:
        #   def self.call(context)  →  Array<[[text, style], ...]>
        module HeaderLinePipeline
          Context = Struct.new(:classifier, :diagram_package_id,
                               :visually_nested, :umldi_keyword,
                               :bounds_width, :font_size,
                               :off_canvas_parent_name,
                               keyword_init: true)

          PROVIDERS = [
            HeaderLineProvider::ParentGhost,
            HeaderLineProvider::InstanceSpec,
            HeaderLineProvider::StereotypeLabel,
            HeaderLineProvider::Name
          ].freeze

          # @param classifier [Ea::Model::Classifier, Ea::Model::InstanceSpecification]
          # @return [Array<Array(String, Symbol)>] list of [text, style] pairs
          def self.for(classifier, **opts)
            context = Context.new(classifier: classifier, **opts)
            PROVIDERS.flat_map { |provider| provider.call(context) }
          end
        end
      end
    end
  end
end
