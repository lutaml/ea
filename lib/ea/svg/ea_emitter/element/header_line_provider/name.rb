# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        module HeaderLineProvider
          # Emits the classifier's display name, with these behaviors:
          #
          # - Bold-italic for abstract Klass; bold otherwise.
          # - Foreign elements (owning package ≠ the diagram's package,
          #   gated on t_diagram.ShowForeign) render the qualified
          #   name "OwningPackage::Name".
          # - Qualified-name wrap: when the combined integer
          #   textLength exceeds the element bounds width, EA splits
          #   "pkg::Class" across two lines ("pkg::" then "Class"),
          #   each centered independently. Corpus-verified: every
          #   wrapped header overflows its box and every single-line
          #   header fits (tightest observed slack 6px).
          #
          # InstanceSpecification returns [] (InstanceSpec provider
          # already emitted the full label).
          class Name
            def self.call(context)
              classifier = context.classifier
              return [] if classifier.is_a?(Ea::Model::InstanceSpecification)

              weight = weight_for(classifier)
              wrapped_name_lines(classifier, context, weight)
            end

            # @param classifier [Ea::Model::Classifier]
            # @return [Symbol] :bold_italic for abstract, :bold otherwise
            def self.weight_for(classifier)
              classifier.is_a?(Ea::Model::Klass) && classifier.is_abstract ? :bold_italic : :bold
            end

            def self.wrapped_name_lines(classifier, context, weight)
              name = display_name(classifier)
              name = "#{context.foreign_package_name}::#{name}" if context.foreign_package_name
              unless context.bounds_width && name_exceeds_bounds?(name, context, weight)
                return [[name, weight]]
              end

              if name.include?("::")
                qualifier, base = name.split("::", 2)
                [["#{qualifier}::", weight], [base, weight]]
              else
                HeaderLinePipeline.wrap_words(name, context, weight).map do |line|
                  [line, weight]
                end
              end
            end

            def self.name_exceeds_bounds?(name, context, weight)
              font_style = weight == :bold_italic ? "italic" : "normal"
              len = TextRenderer.estimate_width(
                name, context.font_size || 9, nil,
                family: context.family, weight: "700", style: font_style
              ).round
              # Same usable width as wrap_words: box width - 6.
              # EA wraps "Content information::MD_FeatureCatalogue-
              # Description" (parts 86 + 137 + space 4 = 227) inside
              # a 230px box (F851A657).
              len > context.bounds_width.to_i - 6
            end

            # EA renders the plain classifier name in element headers;
            # qualification is layered on by the pipeline via
            # context.foreign_package_name.
            def self.display_name(classifier, *_)
              classifier.name.to_s
            end
          end
        end
      end
    end
  end
end
