# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Per-connector label renderers. Each renderer handles one
      # visual label kind on a connector:
      #
      #   EndLabel       - role + «property» + multiplicity at
      #                    LLT/LRT box positions (UML associations)
      #   MidpointLabel  - «stereotype» at the connector midpoint
      #                    (Package / Dependency / Realization)
      #
      # Registry dispatches by relationship kind so new label kinds
      # register rather than editing the orchestrator (OCP).
      module Label
        autoload :EndLabel, "ea/svg/ea_emitter/label/end_label"
        autoload :TargetBendSeat, "ea/svg/ea_emitter/label/target_bend_seat"
        autoload :SourceStairSeat, "ea/svg/ea_emitter/label/source_stair_seat"
        autoload :PlainSourceSeat, "ea/svg/ea_emitter/label/plain_source_seat"
        autoload :PlainTargetSeat, "ea/svg/ea_emitter/label/plain_target_seat"
        autoload :MidpointLabel, "ea/svg/ea_emitter/label/midpoint_label"
        autoload :Registry, "ea/svg/ea_emitter/label/registry"
      end
    end
  end
end
