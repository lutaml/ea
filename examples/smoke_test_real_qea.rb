#!/usr/bin/env ruby
# frozen_string_literal: true

# End-to-end smoke test: parse a real Sparx EA .qea file end-to-end through
# both the standalone QEA loader and the UML bridge.
#
# Run: bundle exec ruby examples/smoke_test_real_qea.rb
#
# Demonstrates:
#   1. Ea::Qea.database_info  — quick table-count stats (no full load)
#   2. Ea::Qea.load           — standalone load → Ea::Qea::Database
#   3. Ea::Qea.to_uml         — bridge → Lutaml::Uml::Document
#
# Requires a real .qea file. Defaults to the plateau model fixture; override
# with the QEA_PATH environment variable.

require "bundler/setup"
require "lutaml/uml"
require "ea"

QEA_PATH = ENV.fetch(
  "QEA_PATH",
  "/Users/mulgogi/src/mn/plateau-model/20251010_current_plateau_v5.1.qea",
)

abort "QEA not found: #{QEA_PATH}" unless File.exist?(QEA_PATH)

puts "QEA: #{QEA_PATH}"
puts "Size: #{(File.size(QEA_PATH) / 1_048_576.0).round(2)} MB"
puts

# 1. Quick stats — opens the SQLite DB and counts rows per table, no model load
puts "== database_info (quick stats, top 12 tables) =="
Ea::Qea.database_info(QEA_PATH)
  .sort_by { |_, count| -count.to_i }
  .first(12)
  .each { |table, count| puts "  #{table}: #{count}" }
puts

# 2. Standalone load — pure QEA parsing, no lutaml-uml needed
puts "== Ea::Qea.load (standalone) =="
database = Ea::Qea.load(QEA_PATH)
puts "  loaded:        #{database.class}"
puts "  total_records: #{database.total_records}"
puts

puts "== EA objects by type =="
database.objects.group_by(:object_type)
  .sort_by { |_, objs| -objs.size }
  .each { |type, objs| puts "  #{type}: #{objs.size}" }
puts

# 3. UML bridge — compose with lutaml-uml to get a Lutaml::Uml::Document
puts "== Ea::Qea.to_uml (bridge) =="
document = Ea::Qea.to_uml(database)
puts "  document: #{document.class}"
puts

# 4. Walk the package tree — classes live inside packages, not at document root
def walk(pkgs, counters)
  Array(pkgs).each do |pkg|
    counters[:packages] += 1
    counters[:classes] += Array(pkg.classes).size
    counters[:enums] += Array(pkg.enums).size
    counters[:data_types] += Array(pkg.data_types).size
    counters[:instances] += Array(pkg.instances).size
    walk(pkg.packages, counters)
  end
end

puts "== UML Document (incl. nested in packages) =="
counters = { packages: 0, classes: 0, enums: 0, data_types: 0, instances: 0 }
walk(document.packages, counters)
counters.each { |k, v| puts "  #{k}: #{v}" }
puts "  associations (document root): #{document.associations.size}"
puts "  diagrams (document root):     #{document.diagrams.size}"
puts "  orphan classes (document root): #{document.classes.size}"
puts "    ^ classes whose EA package_id has no t_package row"
puts

puts "SMOKE TEST PASSED"
