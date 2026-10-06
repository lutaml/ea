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
                               :suppress_stereotypes,
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
          # EA wraps overflowing headers at word boundaries and after
          # "::" qualifiers (F851A657: class "Content
          # information::MD_FeatureCatalogueDescription" renders as
          # "Content information::" / "MD_FeatureCatalogueDescription";
          # 81F92FC7: instance header "new ownership: LA_Right"
          # renders as "new ownership:" / "LA_Right").
          # Headers wrap against a USABLE width of box width - 6:
          # EA wrapped "SU_PB2: LA_SpatialUnit" (parts 36 + 59 +
          # space 4 = 99) inside a 100px box, while
          # "FuelStation: LA_BAUnit" (94) stayed single in a 100px
          # box - the corpus boundary is margin 5 wrapped vs 6
          # unwrapped (FC590D99 vs CBC03448).
          def self.wrap_words(text, context, weight)
            font_style = weight == :bold_italic ? "italic" : "normal"
            width = lambda do |s|
              TextRenderer.estimate_width(
                s, context.font_size || 9, nil,
                family: context.family, weight: "700", style: font_style
              ).round
            end
            return [text] if context.bounds_width.nil?
            usable = context.bounds_width.to_i - 6
            return [text] if width.call(text) <= usable

            segments = wrap_segments(text)
            lines = []
            current = +""
            segments.each do |segment|
              candidate = current + segment
              if !current.empty? && width.call(candidate) > usable
                lines << current
                current = +segment.lstrip
              else
                current = candidate
              end
            end
            lines << current unless current.empty?
            lines
          end

          # Break opportunities: after each space and after each
          # "::". Each segment carries the separator that PRECEDES
          # it ("" after "::", " " after a word), so joining all
          # segments reproduces the original text exactly.
          def self.wrap_segments(text)
            segments = []
            pending = ""
            text.split(" ").each do |word|
              chunk = +""
              word.split(/(::)/).each_slice(2) do |part, sep|
                chunk << pending << part
                pending = ""
                if sep
                  chunk << sep
                  segments << chunk.dup
                  chunk.clear
                end
              end
              unless chunk.empty?
                segments << chunk.dup
                pending = " "
              end
            end
            segments
          end
        end
      end
    end
  end
end
