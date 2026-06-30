# frozen_string_literal: true

module Ea
  module Transformers
    module UmlToXmi
      # Allocates xmi:id values for UML elements during lossy serialization.
      #
      # Strategy:
      #   1. If the element already has an `xmi_id` (set by the QEA factory
      #      during parsing), reuse it.
      #   2. Otherwise synthesize a stable `EAID_…` from a counter.
      #
      # This class is used only by the lossy {UmlToXmi::Transformer} path.
      # The full-fidelity {QeaToXmi} path uses {QeaToXmi::GuidFormat} to
      # normalize raw EA GUIDs.
      class IdGenerator
        PREFIX = "EAID"
        MODEL_ID = "#{PREFIX}_EA_MODEL"

        def initialize
          @assigned = {} # object_id → xmi:id
          @counter = 0
        end

        def eaid_for(element)
          key = element.object_id
          @assigned[key] ||= begin
            @counter += 1
            extract_id(element) || synthesize(@counter)
          end
        end

        def model_id
          MODEL_ID
        end

        private

        # `Lutaml::Uml::Value` exposes its XMI identifier via `id` (it does
        # not inherit from TopElement, so it has no `xmi_id`). All other
        # serializable UML types use `xmi_id`.
        def extract_id(element)
          return element.id if element.is_a?(Lutaml::Uml::Value)

          element.xmi_id
        end

        def synthesize(n)
          format("%<prefix>s_%<hex>08X", prefix: PREFIX, hex: n)
        end
      end
    end
  end
end
