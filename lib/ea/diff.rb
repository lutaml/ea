# frozen_string_literal: true

module Ea
  # Structural diff between two EA databases (or pre-parsed models).
  # Returns a list of `Diff::Change` records describing what was added,
  # removed, or modified.
  #
  # Compares by entity identity (table + primary key) and surfaces
  # human-readable change descriptions.
  module Diff
    autoload :Change, "ea/diff/change"
    autoload :Comparator, "ea/diff/comparator"
    autoload :HtmlReporter, "ea/diff/html_reporter"
  end
end
