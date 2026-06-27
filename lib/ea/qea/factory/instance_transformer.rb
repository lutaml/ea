# frozen_string_literal: true

module Ea
  module Qea
    module Factory
      # Transforms EA objects (Object type) to UML instances
      class InstanceTransformer < BaseTransformer
        # Transform EA object to UML instance
        # @param ea_object [EaObject] EA object model
        # @return [Lutaml::Uml::Instance] UML instance
        def transform(ea_object) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
          return nil if ea_object.nil?
          return nil unless ea_object.instance?

          Lutaml::Uml::Instance.new.tap do |instance|
            # Map basic properties
            instance.name = ea_object.name
            instance.xmi_id = normalize_guid_to_xmi_format(ea_object.ea_guid,
                                                           "EAID")

            # Map classifier (the class this is an instance of)
            if ea_object.classifier&.positive?
              classifier_obj = find_classifier(ea_object.classifier)
              if classifier_obj
                instance.classifier = classifier_obj.name
              end
            elsif ea_object.classifier_guid && !ea_object.classifier_guid.empty?
              classifier_obj = find_classifier_by_guid(
                ea_object.classifier_guid,
              )
              if classifier_obj
                instance.classifier = classifier_obj.name
              end
            end

            # Map definition/notes
            instance.definition = ea_object.note unless
              ea_object.note.nil? || ea_object.note.empty?

            # Load and transform tagged values
            instance.tagged_values = load_tagged_values(ea_object.ea_guid)
          end
        end

        private

        # Find classifier object by ID
        # @param classifier_id [Integer] Classifier object ID
        # @return [EaObject, nil] EA object or nil if not found
        def find_classifier(classifier_id)
          return nil if classifier_id.nil? || classifier_id.zero?

          database.find_object(classifier_id)
        end

        # Find classifier object by GUID
        # @param classifier_guid [String] Classifier GUID
        # @return [EaObject, nil] EA object or nil if not found
        def find_classifier_by_guid(classifier_guid)
          return nil if classifier_guid.nil? || classifier_guid.empty?

          database.find_object_by_guid(classifier_guid)
        end

      end
    end
  end
end
