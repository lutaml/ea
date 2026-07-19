# frozen_string_literal: true

require "lutaml/model"

module Ea
  # Ea::Spa is the SPA consumer adapter — a one-way projection of
  # Ea::Model into view-shaped artifacts (Skeleton, Shard,
  # SearchIndex, PackageTree) suitable for a browser frontend.
  #
  # Projection vs. modeling: the SPA does not redefine what a Class
  # is. It owns view-shaped types that refer to model elements by
  # id and add browsing-specific metadata (shard URLs, lazy refs,
  # search content, navigation tree position).
  #
  # Output strategies (single-file vs sharded) live under
  # Ea::Spa::Output and project the same artifacts to disk.
  module Spa
    autoload :SkeletonEntry, "ea/spa/skeleton_entry"
    autoload :Skeleton, "ea/spa/skeleton"
    autoload :PackageTreeNode, "ea/spa/package_tree_node"
    autoload :PackageTree, "ea/spa/package_tree"
    autoload :SearchEntry, "ea/spa/search_entry"
    autoload :SearchIndex, "ea/spa/search_index"
    autoload :Shard, "ea/spa/shard"
    autoload :LazyRef, "ea/spa/lazy_ref"
    autoload :Projector, "ea/spa/projector"
    autoload :Output, "ea/spa/output"
    autoload :Generator, "ea/spa/generator"
  end
end
