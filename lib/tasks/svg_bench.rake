# frozen_string_literal: true

require "ea"
require "ea/svg/parity"

module Ea
  module Svg
    module Parity
      # Formatting shared by the benchmark tasks; parity baselines use CorpusReport.
      module BenchOutput
        def self.shape_counts(counts, width:)
          %i[rect path polygon text].each do |key|
            ours = counts[:ours][key]
            reference = counts[:reference][key]
            delta = ours - reference
            puts "  #{key.to_s.ljust(7)} ours=#{ours.to_s.rjust(width)} ref=#{reference.to_s.rjust(width)} " \
                 "delta=#{delta.to_s.rjust(5)} (#{percentage(delta, reference)}%)"
          end
        end

        def self.percentage(delta, reference)
          reference.zero? ? 0.0 : (delta.to_f / reference * 100).round(1)
        end

        def self.reference_dir(exports_dir, name)
          # EA export folders may omit a QEA version suffix such as ".1".
          names = [name, name.sub(/\.\d+$/, "")]
          paths = names.product(%w[images Images]).map do |base, images|
            File.join(exports_dir, base, images)
          end
          paths.find { |path| Dir.exist?(path) }
        end
      end
    end
  end
end

desc "Report Suite deltas and write a YAML baseline (SOURCE, REF_DIR, OUTPUT_PATH=parity-baseline.yml)"
task "svg:parity_report", %i[source ref_dir output_path] do |_t, args|
  source = args[:source]
  ref_dir = args[:ref_dir]
  abort "usage: rake svg:parity_report[source,ref_dir,output_path]" unless source && ref_dir
  abort "source not found: #{source}" unless File.exist?(source)
  abort "ref_dir not found: #{ref_dir}" unless Dir.exist?(ref_dir)

  doc = Ea::Svg::Parity::Source.new(source).load
  Ea::Svg::Parity::CorpusReport.new(document: doc, ref_dir: ref_dir)
                               .run_baseline(output_path: args[:output_path] || "parity-baseline.yml")
end

desc "Score rendered SVG against EA reference SVGs (SOURCE.xmi or .qea + REF_DIR)"
task "svg:bench", %i[source ref_dir tolerance] do |_t, args|
  source = args[:source] || ENV["EA_BENCH_SOURCE"] ||
           File.expand_path("~/src/mn/mn-samples-plateau/sources/xmi/plateau_all_packages_export.xmi")
  ref_dir = args[:ref_dir] || ENV["EA_BENCH_REF_DIR"] ||
            File.expand_path("~/src/mn/mn-samples-plateau/sources/001-mds/xmi-images")
  tolerance = (args[:tolerance] || ENV["EA_BENCH_TOLERANCE"] || "5").to_i

  abort "source not found: #{source}" unless File.exist?(source)
  abort "ref_dir not found: #{ref_dir}" unless Dir.exist?(ref_dir)

  doc = Ea::Svg::Parity::Source.new(source).load
  suite = Ea::Svg::Parity::Suite.new(doc, ref_dir).measure
  agg = suite.aggregate_shape_counts

  puts "Source: #{source}"
  puts "Refs:   #{ref_dir}"
  puts "Diagrams: #{suite.total} (matched: #{suite.matched(shape_tolerance: tolerance)})"
  Ea::Svg::Parity::BenchOutput.shape_counts(agg, width: 6)
  puts "Text overlap avg: #{(suite.text_overlap_avg * 100).round(1)}%"

  outliers = suite.outliers(shape_tolerance: tolerance)
  unless outliers.empty?
    puts "\nOutliers (#{outliers.size}):"
    outliers.first(20).each do |dr|
      r = dr.report
      puts "  #{dr.id} (#{dr.name}): shape_delta=#{r.shape_delta_total} text=#{r.text_delta}"
    end
  end
end

desc "Bench every example QEA in examples/qea against its exports/Images"
task "svg:examples" do
  project_root = File.expand_path("../..", __dir__)
  qea_dir = File.join(project_root, "examples", "qea")
  exports_dir = File.join(project_root, "examples", "exports")

  abort "examples/qea not found at #{qea_dir}" unless Dir.exist?(qea_dir)

  Dir.glob("#{qea_dir}/*.qea").sort.each do |qea_path|
    name = File.basename(qea_path, ".qea")
    ref_dir = Ea::Svg::Parity::BenchOutput.reference_dir(exports_dir, name)
    if ref_dir.nil?
      puts "#{name}: SKIP (no exports/images directory)"
      next
    end

    doc = Ea::Sources::Qea::Adapter.from_path(qea_path)
    suite = Ea::Svg::Parity::Suite.new(doc, ref_dir).measure
    agg = suite.aggregate_shape_counts

    matched = suite.matched(shape_tolerance: 5)
    puts "#{name.ljust(40)} #{matched}/#{suite.total} matched"
    Ea::Svg::Parity::BenchOutput.shape_counts(agg, width: 5)
    puts ""
  end
end
