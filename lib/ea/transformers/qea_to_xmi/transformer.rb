# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Orchestrates serialization of an {Ea::Qea::Database} to Sparx XMI.
      #
      # Walks the package tree starting at root packages, dispatching to
      # {EmitterRegistry}-registered emitters for each child element. Each
      # emitter owns the XML shape for its element family; the orchestrator
      # owns traversal order and document framing (XMI root, documentation,
      # uml:Model, profile applications).
      #
      # This is the FULL-FIDELITY path — no Lutaml::Uml::Document
      # intermediate. Sparx-specific concepts (multiplicities, tagged values,
      # stereotypes, primitive types) are preserved because they come straight
      # from the QEA tables.
      class Transformer
        MODEL_NAME = "EA_Model"
        EXPORTER   = "Enterprise Architect"
        VERSION    = "6.5"

        def initialize(database)
          @database = database
        end

        # @return [String] XMI XML document
        def serialize
          QeaToXmi.load_emitters!
          ctx.writer.xmi_root(namespaces: SparxNamespaces::BASE) do
            ctx.writer.documentation(
              exporter: EXPORTER,
              exporter_version: VERSION,
            )
            emit_model
          end
          ctx.writer.to_xml
        end

        private

        def emit_model
          ctx.writer.uml_model(name: MODEL_NAME) do
            package_emitter = EmitterRegistry.for(:package)
            root_packages.each { |pkg| package_emitter.emit(pkg, ctx) }
          end
        end

        def root_packages
          @database.packages.select(&:root?).sort_by { |p| [p.tpos || 0, p.name.to_s] }
        end

        def ctx
          @ctx ||= Context.new(
            database: @database,
            writer: Writer.new,
            id_allocator: IdAllocator.new,
          )
        end
      end
    end
  end
end
