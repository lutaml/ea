# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        module HeaderLineProvider
          # Emits the classifier's display name, with these behaviors:
          #
          # - Bold-italic for abstract Klass; bold otherwise.
          # - Qualified name wrap when the rendered width exceeds the
          #   element bounds. EA splits "pkg::Class" across two lines
          #   when the combined width is too wide.
          #
          # InstanceSpecification returns [] (InstanceSpec provider
          # already emitted the full label).
          class Name
            QUALIFIED_WRAP_WIDTH_FACTOR = 0.55
            QUALIFIED_WRAP_PADDING = 8

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
              name = display_name(classifier, context.diagram_package_id,
                                  context.visually_nested)
              unless context.bounds_width && name.include?("::") &&
                     name_exceeds_bounds?(name, context.bounds_width,
                                           context.font_size || 9)
                return [[name, weight]]
              end

              qualifier, base = name.split("::", 2)
              [["#{qualifier}::", weight], [base, weight]]
            end

            def self.name_exceeds_bounds?(name, bounds_width, font_size)
              TextRenderer.estimate_width(name, font_size,
                                          QUALIFIED_WRAP_WIDTH_FACTOR) >
                (bounds_width - QUALIFIED_WRAP_PADDING)
            end

            def self.display_name(classifier, diagram_package_id = nil,
                                  _visually_nested = false)
              name = if classifier.is_a?(Ea::Model::Classifier)
                       (classifier.qualified_name || classifier.name).to_s
                     else
                       classifier.name.to_s
                     end
              return name if diagram_package_id.nil?
              return name unless name.include?("::")

              if classifier.is_a?(Ea::Model::Classifier) &&
                 classifier.package_id == diagram_package_id
                name.split("::").last
              else
                name
              end
            end
          end
        end
      end
    end
  end
end
