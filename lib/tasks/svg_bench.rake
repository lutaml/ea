# frozen_string_literal: true

require "ea"
require "ea/svg/parity"

namespace :svg do
  desc "Score rendered SVG against EA reference SVGs (SOURCE.xmi or .qea + REF_DIR)"
  task :bench, %i[source ref_dir tolerance] do |_t, args|
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
    %i[rect path polygon text].each do |k|
      o = agg[:ours][k]
      r = agg[:reference][k]
      d = o - r
      pct = r.zero? ? 0.0 : (d.to_f / r * 100).round(1)
      puts "  #{k.to_s.ljust(7)} ours=#{o.to_s.rjust(6)} ref=#{r.to_s.rjust(6)} delta=#{d.to_s.rjust(5)} (#{pct}%)"
    end
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
  task :examples do
    project_root = File.expand_path("../..", __dir__)
    qea_dir = File.join(project_root, "examples", "qea")
    exports_dir = File.join(project_root, "examples", "exports")

    abort "examples/qea not found at #{qea_dir}" unless Dir.exist?(qea_dir)

    Dir.glob("#{qea_dir}/*.qea").sort.each do |qea_path|
      name = File.basename(qea_path, ".qea")
      # Strip version suffixes like ".1" from names like
      # "20251010_current_plateau_v5.1" to match the exports
      # directory "20251010_current_plateau_v5".
      stripped_name = name.sub(/\.\d+$/, "")
      # Reference images live in examples/exports/<name>/images or Images
      candidates = [
        File.join(exports_dir, name, "images"),
        File.join(exports_dir, name, "Images"),
        File.join(exports_dir, stripped_name, "images"),
        File.join(exports_dir, stripped_name, "Images")
      ]
      ref_dir = candidates.find { |p| Dir.exist?(p) }
      if ref_dir.nil?
        puts "#{name}: SKIP (no exports/images directory)"
        next
      end

      doc = Ea::Sources::Qea::Adapter.from_path(qea_path)
      suite = Ea::Svg::Parity::Suite.new(doc, ref_dir).measure
      agg = suite.aggregate_shape_counts

      matched = suite.matched(shape_tolerance: 5)
      puts "#{name.ljust(40)} #{matched}/#{suite.total} matched"
      %i[rect path polygon text].each do |k|
        o = agg[:ours][k]
        r = agg[:reference][k]
        d = o - r
        pct = r.zero? ? 0.0 : (d.to_f / r * 100).round(1)
        puts "  #{k.to_s.ljust(7)} ours=#{o.to_s.rjust(5)} ref=#{r.to_s.rjust(5)} delta=#{d.to_s.rjust(5)} (#{pct}%)"
      end
      puts ""
    end
  end
end
