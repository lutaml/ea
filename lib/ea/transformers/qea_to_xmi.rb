# frozen_string_literal: true

module Ea
  module Transformers
    # Full-fidelity transformer: Ea::Qea::Database → Sparx XMI.
    #
    # Use this for Sparx-to-Sparx round-trip — no intermediate UML model, no
    # loss of Sparx-specific concepts (multiplicities, tagged values,
    # stereotypes, primitive types, instance specifications, association
    # ends). For a tool-agnostic UML document → XMI path, use {UmlToXmi}.
    module QeaToXmi
      autoload :Transformer,      "ea/transformers/qea_to_xmi/transformer"
      autoload :Context,          "ea/transformers/qea_to_xmi/context"
      autoload :Writer,           "ea/transformers/qea_to_xmi/writer"
      autoload :XmlBuilder,       "ea/transformers/qea_to_xmi/xml_builder"
      autoload :IdAllocator,      "ea/transformers/qea_to_xmi/id_allocator"
      autoload :EmitterRegistry,  "ea/transformers/qea_to_xmi/emitter_registry"
      autoload :GuidFormat,       "ea/transformers/qea_to_xmi/guid_format"
      autoload :SparxNamespaces,  "ea/transformers/qea_to_xmi/sparx_namespaces"

      # Emitter classes — each self-registers with EmitterRegistry at file
      # load time, so referencing any one of them fires its registration
      # side effect. {Transformer} calls {.load_emitters!} before serialize
      # to guarantee they're all loaded.
      module Emitters
        autoload :BaseEmitter,           "ea/transformers/qea_to_xmi/emitters/base_emitter"
        autoload :PackageEmitter,        "ea/transformers/qea_to_xmi/emitters/package_emitter"
        autoload :ClassEmitter,          "ea/transformers/qea_to_xmi/emitters/class_emitter"
        autoload :EnumerationEmitter,    "ea/transformers/qea_to_xmi/emitters/enumeration_emitter"
        autoload :DataTypeEmitter,       "ea/transformers/qea_to_xmi/emitters/data_type_emitter"
        autoload :InstanceEmitter,       "ea/transformers/qea_to_xmi/emitters/instance_emitter"
        autoload :AttributeEmitter,      "ea/transformers/qea_to_xmi/emitters/attribute_emitter"
        autoload :OperationEmitter,      "ea/transformers/qea_to_xmi/emitters/operation_emitter"
        autoload :AssociationEmitter,    "ea/transformers/qea_to_xmi/emitters/association_emitter"
        autoload :GeneralizationEmitter, "ea/transformers/qea_to_xmi/emitters/generalization_emitter"
        autoload :RealizationEmitter,    "ea/transformers/qea_to_xmi/emitters/realization_emitter"
        autoload :DependencyEmitter,     "ea/transformers/qea_to_xmi/emitters/dependency_emitter"
        autoload :CommentEmitter,        "ea/transformers/qea_to_xmi/emitters/comment_emitter"
        autoload :SlotEmitter,           "ea/transformers/qea_to_xmi/emitters/slot_emitter"
      end

      class << self
        # Force-load all emitter files so their self-registration calls fire.
        # Idempotent — autoload returns immediately once loaded.
        # @return [void]
        def load_emitters!
          Emitters.constants.each { |c| Emitters.const_get(c) }
        end
      end
    end
  end
end
