# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        module HeaderLineProvider
          # Emits the stereotype label `«name»` for classifiers with
          # an explicit stereotype, OR a type-derived fallback
          # («enumeration», «dataType», etc.) for non-Klass classifiers.
          #
          # Plain Klass with no stereotype gets no label — EA's
          # behavior.
          #
          # InstanceSpecification is excluded (it owns its own header).
          class StereotypeLabel
            def self.call(context)
              classifier = context.classifier
              return [] if classifier.is_a?(Ea::Model::InstanceSpecification)
              # Diagram pdata HideEStereo=1 suppresses classifier
              # stereotype lines too (the Annex C "Case" diagrams
              # render zero «...» lines, classes included).
              return [] if context.suppress_stereotypes

              labels = label_for(classifier, context.umldi_keyword, context.stereotype_fqname)
              return [] if labels.empty?

              labels.map { |l| [l, :normal] }
            end

            # @return [Array<String>] «name» labels (EA renders one
            # line per applied stereotype)
            def self.label_for(classifier, umldi_keyword, stereotype_fqname = nil)
              return ["«#{umldi_keyword}»"] if umldi_keyword && !umldi_keyword.empty?

              explicit = explicit_stereotype(classifier, stereotype_fqname)
              return explicit if explicit

              case classifier
              when Ea::Model::Klass, Ea::Model::Package, Ea::Model::Note
                []
              else
                fallback = fallback_name(classifier)
                fallback ? ["«#{fallback}»"] : []
              end
            end

            def self.explicit_stereotype(classifier, stereotype_fqname = nil)
              return nil unless classifier.is_a?(Ea::Model::Classifier) ||
                                 classifier.is_a?(Ea::Model::Package)

              refs = classifier.stereotype_refs
              return nil unless refs&.any?

              refs.map { |ref| "«#{canonical(ref, stereotype_fqname)}»" }
            end

            # EA's standard Class stereotype displays as «type» while
            # its semantic name remains Type. Custom profiles retain case.
            def self.canonical(ref, stereotype_fqname = nil)
              return "type" if ref == "Type" && stereotype_fqname == "StandardProfileL2::Type"

              ref
            end

            def self.fallback_name(classifier)
              case classifier
              when Ea::Model::Enumeration then "enumeration"
              when Ea::Model::DataType then "dataType"
              when Ea::Model::PrimitiveType then "primitive"
              when Ea::Model::Interface then "interface"
              when Ea::Model::Signal then "signal"
              else "DataType"
              end
            end
          end
        end
      end
    end
  end
end
