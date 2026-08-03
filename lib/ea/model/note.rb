# frozen_string_literal: true

module Ea
  module Model
    # A Note element placed on a diagram. Distinct from Annotation
    # (which is metadata attached to another model element) — a
    # Note is a first-class diagram element with its own bounds,
    # rendered as a folded-corner rect containing the body text.
    #
    # When `note_type` is "Text" and StyleEx carries LegendOpts=,
    # EA renders this element as an auto-generated legend block
    # instead of a dog-eared note. The legend configuration is
    # attached via the optional `legend` attribute.
    class Note < Base
      attribute :body, :string
      attribute :note_type, :string # "Note" | "Text" | "File"
      attribute :legend, Legend

      json do
        map "id", to: :id
        map "name", to: :name
        map "body", to: :body
        map "noteType", to: :note_type
        map "legend", to: :legend
      end
    end
  end
end
