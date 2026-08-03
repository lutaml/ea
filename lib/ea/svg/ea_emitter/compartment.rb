# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Compartment pipeline. Each Compartment is a small,
      # single-purpose renderer that decides whether it applies to
      # the current RenderContext and, if so, emits its SVG layer.
      #
      # Adding a new compartment = adding a class to `COMPARTMENTS`.
      # The Elements orchestrator does not change — OCP-friendly.
      module Compartment
        autoload :Shape, "ea/svg/ea_emitter/compartment/shape"
        autoload :NoteBody, "ea/svg/ea_emitter/compartment/note_body"
        autoload :Header, "ea/svg/ea_emitter/compartment/header"
        autoload :HeaderDivider, "ea/svg/ea_emitter/compartment/header_divider"
        autoload :Attributes, "ea/svg/ea_emitter/compartment/attributes"
        autoload :Operations, "ea/svg/ea_emitter/compartment/operations"
        autoload :EnumLiterals, "ea/svg/ea_emitter/compartment/enum_literals"
        autoload :TaggedValues, "ea/svg/ea_emitter/compartment/tagged_values"
        autoload :Constraints, "ea/svg/ea_emitter/compartment/constraints"
        autoload :PackageContents, "ea/svg/ea_emitter/compartment/package_contents"
        autoload :InstanceUnderline, "ea/svg/ea_emitter/compartment/instance_underline"
        autoload :InstanceSlots, "ea/svg/ea_emitter/compartment/instance_slots"
        autoload :NoteText, "ea/svg/ea_emitter/compartment/note_text"
        autoload :PackageFromParent, "ea/svg/ea_emitter/compartment/package_from_parent"

        # Order matters: EA emits compartments top-to-bottom inside
        # each element group.
        ALL = [
          Shape,
          NoteBody,
          Header,
          HeaderDivider,
          Attributes,
          Operations,
          EnumLiterals,
          TaggedValues,
          Constraints,
          PackageContents,
          InstanceSlots,
          NoteText,
          PackageFromParent,
          InstanceUnderline
        ].freeze

        module_function

        # Renders every applicable compartment for the context.
        # Returns an Array of SVG strings (some may be nil; the
        # caller compacts).
        def render_all(context)
          ALL.map { |compartment| compartment.render(context) }
        end
      end
    end
  end
end
