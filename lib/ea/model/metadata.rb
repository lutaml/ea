# frozen_string_literal: true

module Ea
  module Model
    # Document-level metadata. Captured during source adaptation;
    # surfaced by the SPA as project info.
    class Metadata < Base
      attribute :title, :string
      attribute :version, :string
      attribute :author, :string
      attribute :company, :string
      attribute :created_date, :string
      attribute :modified_date, :string
      attribute :source_format, :string  # "qea" | "xmi"
      attribute :source_tool, :string    # e.g. "Sparx EA 16.0"
      attribute :source_path, :string

      json do
        map "title", to: :title
        map "version", to: :version
        map "author", to: :author
        map "company", to: :company
        map "createdDate", to: :created_date
        map "modifiedDate", to: :modified_date
        map "sourceFormat", to: :source_format
        map "sourceTool", to: :source_tool
        map "sourcePath", to: :source_path
      end
    end
  end
end
