# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Builds Ea::Model::Annotation instances from EA Note text and
      # t_document rows. EA stores most documentation as a Note
      # field directly on the element (t_object.Note, t_package.notes,
      # t_connector.notes, t_attribute.notes, etc.); we lift each
      # non-empty note into a typed Annotation.
      class AnnotationBuilder
        attr_reader :owner_guid

        def initialize(owner_guid)
          @owner_guid = owner_guid
        end

        def self.from_note(note_text, owner_guid, kind: "documentation")
          return [] if note_text.nil? || note_text.empty?

          [new(owner_guid).build(kind, note_text)]
        end

        def build(kind, body, author: nil, modified_date: nil)
          Ea::Model::Annotation.new(
            id: IdNormalizer.synthetic("annotation", owner_guid, kind),
            kind: kind,
            body: body,
            author: author,
            modified_date: modified_date
          )
        end
      end
    end
  end
end
