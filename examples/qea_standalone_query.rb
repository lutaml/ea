#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Standalone QEA loading and querying (no lutaml-uml required).
#
# The `ea` gem's core is a standalone Sparx EA QEA parser. You can load a
# .qea file and query the EA-native data structures directly — useful when
# you only need EA metadata, statistics, or specific table rows and don't
# want the UML metamodel in your dependency tree.
#
# Run: bundle exec ruby examples/qea_standalone_query.rb

require "bundler/setup"
require "ea"

QEA_PATH = ENV.fetch(
  "QEA_PATH",
  "/Users/mulgogi/src/mn/plateau-model/20251010_current_plateau_v5.1.qea",
)

abort "QEA not found: #{QEA_PATH}" unless File.exist?(QEA_PATH)

# Load the complete database. Returns an Ea::Qea::Database — an immutable
# container with lazy-built indexes for O(1) lookups.
#
# NOTE: EA objects expose their database primary key as `ea_object_id`, NOT
# `object_id`. Ruby's built-in `Object#object_id` (memory address) shadows
# any attribute named `object_id`, so always use `ea_object_id`.
database = Ea::Qea.load(QEA_PATH)

# Each EA table is exposed as a repository (Enumerable, with find/where/pluck).
puts "Loaded #{database.total_records} records across #{database.collection_names.size} collections"
puts

# Example queries ----------------------------------------------------------

# 1. Find a class with attributes inside a real package.
#    Use `ea_object_id` (the DB primary key), never `object_id`.
sample = database.objects
  .select { |o| o.object_type == "Class" && o.name && !o.name.empty? }
  .select { |o| database.find_package(o.package_id) }
  .select { |o| database.attributes_for_object(o.ea_object_id).any? }
  .first
puts "Sample class: #{sample.name} (ea_object_id=#{sample.ea_object_id})"
puts

# 2. All connectors for that class
connectors = database.connectors_for_object(sample.ea_object_id)
puts "Connectors for #{sample.name}: #{connectors.size}"
connectors.first(3).each do |c|
  puts "  type=#{c.connector_type} dest=#{c.destelement.inspect} src=#{c.sourceelement.inspect}"
end
puts

# 3. All attributes for that class
attributes = database.attributes_for_object(sample.ea_object_id)
puts "Attributes for #{sample.name}: #{attributes.size}"
attributes.first(3).each { |a| puts "  #{a.name}: #{a.type}" }
puts

# 4. Tagged values (stereotype properties) for the class
tags = database.tagged_values_for_element(sample.ea_guid)
puts "Tagged values for #{sample.name}: #{tags.size}"
tags.first(3).each { |t| puts "  #{t.property}: #{t.value}" if t.value && !t.value.empty? }
puts

# 5. Packages hierarchy
root_packages = database.packages.select { |p| p.parent_id.nil? || p.parent_id.zero? }
puts "Root packages: #{root_packages.size}"
root_packages.each do |pkg|
  children = database.child_packages_for(pkg.package_id)
  puts "  #{pkg.name} (id=#{pkg.package_id}, #{children.size} children)"
end
