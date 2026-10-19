# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      class DiagramBuilder
        # Association-class tethers use coincident proxies as the saved
        # association anchor; PDATA1 identifies the attached classifier.
        module AssociationClass
          private

          def mark_association_class(model, connector, diagram)
            return model unless association_class_connector?(connector) && association_proxies?(connector)

            attached = placed_association_class(connector, diagram)
            return model unless attached && coincident_anchors?(model)

            model.style[:association_class_ref] = IdNormalizer.from_guid(attached.ea_guid)
            model
          end

          def association_class_connector?(connector)
            connector&.connector_type == "Association" && connector.subtype == "Class" &&
              connector.pdata1.to_s.match?(/\A[1-9]\d*\z/)
          end

          def placed_association_class(connector, diagram)
            attached = database.find_object(connector.pdata1.to_i)
            return unless attached&.object_type == "Class"
            return unless diagram_object_placement(diagram.diagram_id, attached.ea_object_id)

            attached
          end

          def association_proxies?(connector)
            proxies = [connector.start_object_id, connector.end_object_id].map { |id| database.find_object(id) }
            return false unless proxies.all? { |object| object&.object_type == "ProxyConnector" }

            guid = proxies.first.classifier_guid
            !guid.to_s.empty? && guid == proxies.last.classifier_guid
          end

          def coincident_anchors?(model)
            first = model.source_anchor
            last = model.target_anchor
            first && last && first.x == last.x && first.y == last.y
          end
        end
      end
    end
  end
end
