# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Marker
        # Open triangle marker for UML generalization, realization,
        # and dependency. Generalization/Realization render a
        # white-filled 3-point polygon at the general / supplier end;
        # DEPENDENCY renders a line-style open path triangle (same
        # style group as the connector line) — corpus-verified on
        # E58034A3 where 22 directed dependencies converging on one
        # package each draw a 'M a b L c d L a e' path triangle while
        # the diagram's generalizations use polygons.
        class OpenTriangle < Kind
          def self.handles?(effective_type)
            %w[Generalization Realization Realisation Dependency
               InformationFlow NoteLink].include?(effective_type)
          end

          def self.specs_for(connector, source, target, before_target, after_source, relationship: nil)
            whole_end_at_source = whole_end_at_source?(connector)
            anchor = whole_end_at_source ? target : source
            base = whole_end_at_source ? before_target : after_source
            shape = if %w[Dependency InformationFlow].include?(effective_type?(connector))
                    :dependency_arrow
                  else
                    :triangle
                  end
            [Registry::Spec.new(shape: shape, anchor: anchor, base: base)]
          end

          def self.effective_type?(connector)
            connector.connector_type
          end
        end
      end
    end
  end
end

Ea::Svg::EaEmitter::Marker::Registry.register(Ea::Svg::EaEmitter::Marker::OpenTriangle)
