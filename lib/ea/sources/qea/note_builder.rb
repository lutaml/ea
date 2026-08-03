# frozen_string_literal: true

module Ea
  module Sources
    module Qea
      # Extracts Note elements from EA's t_object table. Notes have
      # object_type="Note" and are filtered out by ClassifierBuilder.
      # Their body text lives in t_object.Note; the diagram renderer
      # emits them as dog-eared rects with the body wrapped inside.
      #
      # Text elements (object_type="Text") with LegendOpts= in
      # StyleEx are auto-generated legend blocks rather than notes;
      # their configuration is parsed from t_xref and attached as
      # an `Ea::Model::Legend` payload on the Note.
      class NoteBuilder
        NOTE_OBJECT_TYPE = "Note".freeze
        TEXT_OBJECT_TYPE = "Text".freeze
        LEGEND_STYLEEX_TOKEN = "LegendOpts=".freeze

        attr_reader :database

        def initialize(database)
          @database = database
        end

        def build_all
          objects = database.collections[:objects] || []
          objects.filter_map { |obj| build_one(obj) }
        end

        private

        def build_one(obj)
          return nil unless note_type?(obj.object_type)

          Ea::Model::Note.new(
            id: IdNormalizer.from_guid(obj.ea_guid),
            name: obj.name,
            body: obj.note,
            note_type: obj.object_type,
            legend: legend_for(obj)
          )
        end

        def note_type?(object_type)
          object_type == NOTE_OBJECT_TYPE || object_type == TEXT_OBJECT_TYPE
        end

        def legend_for(obj)
          return nil unless obj.object_type == TEXT_OBJECT_TYPE
          return nil unless obj.styleex.to_s.include?(LEGEND_STYLEEX_TOKEN)

          LegendBuilder.new(database).build_for(obj.ea_guid)
        end
      end
    end
  end
end
