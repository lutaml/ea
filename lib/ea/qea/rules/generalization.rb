# frozen_string_literal: true

module Ea
  module Qea
    module Rules
      # Generalization traversal rules. EA's Generalization connector
      # points from the specific (child) to the general (parent):
      # Start_Object_ID is the child, End_Object_ID is the parent.
      module Generalization
        module_function

        # The generalization connector whose child (start) is the given
        # object — i.e. the object's direct parent link.
        # @param object_id [Integer, nil] child Object_ID
        # @param connectors [Array<Ea::Qea::Models::EaConnector>]
        # @return [Ea::Qea::Models::EaConnector, nil]
        def connector_for(object_id, connectors)
          return nil if object_id.nil?

          connectors.find do |c|
            c.generalization? && c.start_object_id == object_id
          end
        end

        # All generalization connectors originating at the given child.
        # @param object_id [Integer, nil]
        # @param connectors [Array<Ea::Qea::Models::EaConnector>]
        # @return [Array<Ea::Qea::Models::EaConnector>]
        def connectors_from(object_id, connectors)
          return [] if object_id.nil?

          connectors.select do |c|
            c.generalization? && c.start_object_id == object_id
          end
        end
      end
    end
  end
end
