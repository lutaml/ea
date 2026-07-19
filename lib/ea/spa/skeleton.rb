# frozen_string_literal: true

module Ea
  module Spa
    # Top-level SPA skeleton. Plain Struct (not a lutaml-model
    # type) because it's a thin transport wrapper around typed
    # sub-objects (PackageTree, SkeletonEntry) plus a raw metadata
    # hash extracted from the model.
    Skeleton = Struct.new(:metadata, :package_tree, :entries, :view_extras,
                          keyword_init: true) do
      def to_json(*args)
        payload = {
          "metadata" => metadata,
          "packageTree" => package_tree,
          "entries" => entries
        }
        payload["viewExtras"] = view_extras unless view_extras.nil? || view_extras.empty?
        JSON.generate(payload, *args)
      end
    end
  end
end
