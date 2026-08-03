# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Namespace for HeaderLinePipeline providers. Each provider
        # owns ONE contribution to the header. Adding a new line type
        # (e.g. legend symbol) = adding a new provider here.
        module HeaderLineProvider
          autoload :ParentGhost, "ea/svg/ea_emitter/element/header_line_provider/parent_ghost"
          autoload :InstanceSpec, "ea/svg/ea_emitter/element/header_line_provider/instance_spec"
          autoload :StereotypeLabel, "ea/svg/ea_emitter/element/header_line_provider/stereotype_label"
          autoload :Name, "ea/svg/ea_emitter/element/header_line_provider/name"
        end
      end
    end
  end
end
