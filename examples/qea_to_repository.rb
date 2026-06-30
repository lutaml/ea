#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: QEA → UML Document → UmlRepository composition.
#
# This is the recommended composition pattern for getting from a .qea file to
# a queryable Lutaml::UmlRepository::Repository. Each gem does one job:
#
#   ea                  parses .qea → Lutaml::Uml::Document
#   lutaml-uml          wraps the Document in a queryable Repository
#
# No gem reaches into another at load time. The caller composes.
#
# Run: bundle exec ruby examples/qea_to_repository.rb

require "bundler/setup"
require "ea"
require "lutaml/uml"
require "lutaml/uml_repository"

QEA_PATH = ENV.fetch(
  "QEA_PATH",
  "/Users/mulgogi/src/mn/plateau-model/20251010_current_plateau_v5.1.qea",
)

abort "QEA not found: #{QEA_PATH}" unless File.exist?(QEA_PATH)

# Step 1: ea parses the .qea into a UML Document.
puts "Parsing #{File.basename(QEA_PATH)}..."
document = Ea::Qea.parse(QEA_PATH)
puts "  → #{document.class} (#{document.packages.size} root packages)"
puts

# Step 2: lutaml-uml wraps the document in a queryable repository.
#   This is composition — no load-time registration, no hidden coupling.
repo = Lutaml::UmlRepository::Repository.from_document(document)
puts "Wrapped in #{repo.class}"
puts

# Step 3: use the repository's query API.
puts "Repository queries:"
puts "  total classes: #{repo.all_classes.size}"
puts "  total diagrams: #{repo.all_diagrams.size}"

# find_class takes a qualified name like "ModelRoot::Pkg::ClassName".
# Here we just take the first one from the index to demonstrate.
first_id, first_class = repo.all_classes.first
if first_class
  puts
  puts "Sample class from repository: #{first_class.respond_to?(:name) ? first_class.name : first_id}"
end
