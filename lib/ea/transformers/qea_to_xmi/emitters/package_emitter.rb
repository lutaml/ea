# frozen_string_literal: true

require "set"

module Ea
  module Transformers
    module QeaToXmi
      module Emitters
        # Emits a `<packagedElement uml:Package>` and recursively its children.
        #
        # Children are emitted in this order to match Sparx output:
        #
        #   1. ownedComment — Note/Text objects attached to the package
        #   2. Sub-packages (recursive)
        #   3. Classifier packagedElements (Class, Enumeration, DataType, etc.)
        #      — generalizations and realizations are emitted inside the
        #      classifier by ClassEmitter, not here
        #   4. Relationship packagedElements owned by this package
        #      (Association, Dependency — emitted at the package level)
        #
        # Within each category, ordering is by `tpos` then name.
        class PackageEmitter < BaseEmitter
          PACKAGE_LEVEL_RELATIONSHIPS = {
            "Association" => :association,
            "Aggregation" => :association,
            "Composition" => :association,
            "Dependency"  => :dependency,
            "Usage"       => :dependency,
          }.freeze

          def emit(package, ctx)
            ctx.writer.packaged_element(
              xmi_type: "uml:Package",
              xmi_id: ctx.xmi_id_for(package, prefix: "EAPK"),
              name: package.name,
            ) do
              emit_children(package, ctx)
            end
          end

          private

          def emit_children(package, ctx)
            emit_comments(package, ctx)
            emit_sub_packages(package, ctx)
            emit_classifier_objects(package, ctx)
            emit_package_level_relationships(package, ctx)
          end

          def emit_comments(package, ctx)
            note_objects = objects_in(package, ctx).select { |o| note?(o) }
            sorted_by_position(note_objects).each do |obj|
              CommentEmitter.new.emit(obj, ctx)
            end
          end

          def emit_sub_packages(package, ctx)
            sorted_by_position(ctx.child_packages(package.package_id)).each do |sub|
              self.class.new.emit(sub, ctx)
            end
          end

          def emit_classifier_objects(package, ctx)
            sorted_by_position(classifiers_in(package, ctx)).each do |obj|
              emitter = EmitterRegistry.for?(classifier_kind(obj))
              next unless emitter

              emitter.emit(obj, ctx)
            end
          end

          # Walk every object in this package; for each, find connectors where
          # the object is the source. Skip connector types that belong inside
          # the classifier (Generalization, Realization) — those are emitted
          # by ClassEmitter. Dedupe by connector_id so two objects can't
          # double-emit the same connector.
          def emit_package_level_relationships(package, ctx)
            emitted = Set.new
            classifiers_in(package, ctx).each do |obj|
              ctx.connectors_starting_at(obj.ea_object_id).each do |conn|
                key = PACKAGE_LEVEL_RELATIONSHIPS[conn.connector_type]
                next unless key
                next unless emitted.add?(conn.connector_id)

                emitter = EmitterRegistry.for?(key)
                emitter&.emit(conn, ctx)
              end
            end
          end

          def classifier_kind(obj)
            obj.transformer_type || obj.object_type&.downcase&.to_sym
          end

          def classifiers_in(package, ctx)
            objects_in(package, ctx).reject { |o| note?(o) || package_obj?(o) }
          end

          def objects_in(package, ctx)
            ctx.objects_in_package(package.package_id)
          end

          def package_obj?(obj)
            obj.object_type == "Package"
          end

          def note?(obj)
            obj.object_type == "Note" || obj.object_type == "Text"
          end
        end
      end

      EmitterRegistry.register(:package, Emitters::PackageEmitter.new)
    end
  end
end
