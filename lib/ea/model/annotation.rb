# frozen_string_literal: true

module Ea
  module Model
    # First-class annotation: comments, documentation, change notes,
    # requirements, file references — the textual meta-content EA
    # authors attach to model elements.
    #
    # Modeled as a typed concept rather than a packed string, so the
    # SPA can show different annotation kinds with appropriate
    # presentation (e.g. documentation gets rendered as markdown,
    # change history goes in a sidebar).
    class Annotation < Base
      attribute :kind, :string # comment|documentation|change|file|requirement
      attribute :body, :string
      attribute :author, :string
      attribute :modified_date, :string
      attribute :language, :string

      json do
        map "kind", to: :kind
        map "body", to: :body
        map "author", to: :author
        map "modifiedDate", to: :modified_date
        map "language", to: :language
      end
    end
  end
end
