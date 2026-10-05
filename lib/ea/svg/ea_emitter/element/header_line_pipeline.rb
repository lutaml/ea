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
        #   umldi_keyword, bounds_width, font_size, family,
        #   off_canvas_parent_name, foreign_package_name
        #
        # Each provider implements:
        #   def self.call(context)  →  Array<[[text, style], ...]>
        module HeaderLinePipeline
          Context = Struct.new(:classifier, :diagram_package_id,
                               :visually_nested, :umldi_keyword,
                               :bounds_width, :font_size, :family,
                               :off_canvas_parent_name,
                               :foreign_package_name,
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

          # Greedy word wrap measured with the header's own font.
          # EA wraps overflowing headers at word boundaries
          # (81F92FC7: instance header "new ownership: LA_Right"
          # renders as "new ownership:" / "LA_Right").
          def self.wrap_words(text, context, weight)
            font_style = weight == :bold_italic ? "italic" : "normal"
            width = lambda do |s|
              TextRenderer.estimate_width(
                s, context.font_size || 9, nil,
                family: context.family, weight: "700", style: font_style
              ).round
            end
            return [text] if context.bounds_width.nil?
            return [text] if width.call(text) <= context.bounds_width.to_i

            lines = []
            current = +""
            text.split(" ").each do |word|
              candidate = current.empty? ? word : "#{current} #{word}"
              if !current.empty? && width.call(candidate) > context.bounds_width.to_i
                lines << current
                current = word
              else
                current = candidate
              end
            end
            lines << current unless current.empty?
            lines
          end
        end
      end
    end
  end
end
