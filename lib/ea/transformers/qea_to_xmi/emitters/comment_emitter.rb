# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      module Emitters
        # Emits `<ownedComment>` for EA "Note" or "Text" objects.
        #
        # EA's Note object is a comment attached to a specific element via a
        # NoteLink connector. Phase 1 emits the comment body without trying
        # to resolve the NoteLink target — that requires a second pass over
        # connectors of type "NoteLink".
        class CommentEmitter < BaseEmitter
          def emit(object, ctx)
            body = object.note || object.name || ""
            ctx.writer.owned_comment(
              xmi_id: ctx.xmi_id_for(object),
              body: body,
              annotated_id: nil,
            )
          end
        end
      end
    end
  end
end
