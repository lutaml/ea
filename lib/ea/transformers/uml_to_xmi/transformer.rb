# frozen_string_literal: true

module Ea
  module Transformers
    module UmlToXmi
      # Orchestrates transformation of a {Lutaml::Uml::Document} to Sparx XMI.
      #
      # Walks the UML tree (packages → classifiers → features) and emits XML
      # via {Writer}. Each UML element type has its own private emitter method.
      #
      # This is the LOSSY path — Sparx-specific concepts (stereotypes,
      # multiplicities, tagged values, EA extension block) are not modeled in
      # Lutaml::Uml and therefore not emitted. For Sparx-to-Sparx round-trip
      # with full fidelity, use {Ea::Transformers::QeaToXmi}.
      class Transformer
        MODEL_NAME = "EA_Model"

        def initialize(document)
          @document = document
          @id_gen = IdGenerator.new
          @writer = Writer.new
        end

        # @return [String] XMI XML document
        def serialize
          assign_ids!
          @writer.xmi_root do
            @writer.documentation
            @writer.uml_model(@id_gen.model_id, MODEL_NAME) do
              emit_top_level
            end
          end
          @writer.to_xml
        end

        private

        def assign_ids!
          walk_all(@document.packages)
          walk_all(@document.classes)
          walk_all(@document.enums)
          walk_all(@document.data_types)
        end

        def walk_all(elements)
          elements.each { |e| register!(e) }
        end

        def register!(element)
          @id_gen.eaid_for(element)
          case element
          when Lutaml::Uml::Package then register_package!(element)
          when Lutaml::Uml::UmlClass then register_class!(element)
          end
        end

        def register_package!(pkg)
          walk_all(pkg.packages)
          walk_all(pkg.classes)
          walk_all(pkg.enums)
          walk_all(pkg.data_types)
        end

        def register_class!(klass)
          klass.attributes.each { |a| @id_gen.eaid_for(a) }
          klass.operations.each { |o| @id_gen.eaid_for(o) }
        end

        def emit_top_level
          @document.packages.each   { |p| emit_package(@writer, p) }
          @document.classes.each    { |c| emit_class(@writer, c) }
          @document.enums.each      { |e| emit_enum(@writer, e) }
          @document.data_types.each { |d| emit_data_type(@writer, d) }
        end

        def emit_package(w, pkg)
          w.packaged_element("uml:Package", @id_gen.eaid_for(pkg), pkg.name) do
            pkg.packages.each   { |p| emit_package(w, p) }
            pkg.classes.each    { |c| emit_class(w, c) }
            pkg.enums.each      { |e| emit_enum(w, e) }
            pkg.data_types.each { |d| emit_data_type(w, d) }
          end
        end

        def emit_class(w, klass)
          w.packaged_element(
            "uml:Class",
            @id_gen.eaid_for(klass),
            klass.name,
            is_abstract: klass.is_abstract,
          ) do
            klass.attributes.each { |a| emit_attribute(w, a) }
            klass.operations.each { |o| emit_operation(w, o) }
          end
        end

        def emit_enum(w, enum)
          w.packaged_element(
            "uml:Enumeration",
            @id_gen.eaid_for(enum),
            enum.name,
          ) do
            (enum.values || []).each { |v| emit_literal(w, v) }
          end
        end

        def emit_data_type(w, data_type)
          w.packaged_element(
            "uml:DataType",
            @id_gen.eaid_for(data_type),
            data_type.name,
          ) do
            data_type.attributes.each { |a| emit_attribute(w, a) }
            data_type.operations.each { |o| emit_operation(w, o) }
          end
        end

        def emit_attribute(w, attr)
          type_ref = type_reference(attr.type)
          w.owned_attribute(@id_gen.eaid_for(attr), attr.name, type: type_ref) do
            # Multiplicity / defaults not modeled in Lutaml::Uml; deferred.
          end
        end

        def emit_operation(w, op)
          w.owned_operation(@id_gen.eaid_for(op), op.name)
        end

        def emit_literal(w, literal)
          case literal
          when Lutaml::Uml::Value
            w.owned_literal(@id_gen.eaid_for(literal), literal.name)
          when String
            w.owned_literal(synthesize_literal_id(literal), literal)
          else
            w.owned_literal(synthesize_literal_id(literal.to_s), literal.to_s)
          end
        end

        def type_reference(type_name)
          return nil if type_name.nil? || type_name.empty?

          type_name
        end

        def synthesize_literal_id(name)
          format("EAID_LIT_%<hex>08X", hex: name.to_s.bytes.sum)
        end
      end
    end
  end
end
