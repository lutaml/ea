# frozen_string_literal: true

module Ea
  module Diff
    # One structural change between two EA databases.
    #
    # `change` is one of: :added, :removed, :renamed, :modified.
    # `kind` is the collection name (e.g. :packages, :classes).
    # `id` is the entity's primary key (string or int).
    # `name` is a human-readable label for the entity.
    Change = Struct.new(:change, :kind, :id, :name, :details,
                        keyword_init: true) do
      def added?
        change == :added
      end

      def removed?
        change == :removed
      end

      def renamed?
        change == :renamed
      end

      def modified?
        change == :modified
      end
    end
  end
end
