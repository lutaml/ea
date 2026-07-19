# frozen_string_literal: true

module Ea
  module Spa
    # Top-level SPA skeleton. Plain Struct (not a lutaml-model
    # type) because it's a thin transport wrapper around typed
    # sub-objects (PackageTree, SkeletonEntry) plus a raw metadata
    # hash extracted from the model.
    Skeleton = Struct.new(:metadata, :package_tree, :entries,
                          keyword_init: true) do
      def to_json(*args)
        JSON.generate({
                        "metadata" => metadata,
                        "packageTree" => package_tree,
                        "entries" => entries
                      }, *args)
      end
    end
  end
end
