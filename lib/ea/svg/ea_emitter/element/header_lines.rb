# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Legacy entry point preserved for backward compatibility.
        # Delegates to HeaderLinePipeline — the OCP-friendly provider
        # chain that replaces this module. New code should call
        # HeaderLinePipeline directly.
        module HeaderLines
          module_function

          def for(classifier, **opts)
            HeaderLinePipeline.for(classifier, **opts)
          end

          # Delegate to the Name provider so historical callers and
          # specs that test display_name keep working.
          def display_name(classifier, diagram_package_id = nil, *_)
            HeaderLineProvider::Name.display_name(classifier, diagram_package_id)
          end
        end
      end
    end
  end
end
