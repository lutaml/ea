# frozen_string_literal: true

require "ea/fonts/metrics"

namespace :fonts do
  desc "Validate the shipped Carlito metrics against Fontist-resolved TTFs"
  task :validate do
    files = Ea::Fonts::Metrics.carlito_font_files
    abort "Carlito not resolvable via Fontist — install it first" if files.empty?

    shipped = JSON.parse(File.read(Ea::Fonts::Metrics::DATA_PATH))["advance"]
    style_key = { "regular" => "regular", "bold" => "bold",
                  "italic" => "italic", "bold_italic" => "bold_italic",
                  "bolditalic" => "bold_italic" }
    drift = []

    files.each do |style, path|
      table = shipped[style_key[style.downcase]]
      actual = Ea::Fonts::Metrics.advances_from_font(path)
      missing = actual.keys.count { |cp| table[format("U+%04X", cp)].nil? }
      puts "  (shipped table lacks #{missing} of #{actual.size} codepoints — skipped)"
      actual.each do |cp, adv|
        key = format("U+%04X", cp)
        ours = table[key]
        next if ours.nil? || (ours - adv).abs <= 0.0005

        drift << format("%s %s: json=%s font=%s", style, key, ours, adv)
      end
      puts "#{style}: #{path} — #{actual.size} codepoints checked"
    end

    if drift.empty?
      puts "carlito_metrics.json matches the Fontist-resolved fonts."
    else
      puts "DRIFT (#{drift.size} entries):"
      drift.first(20).each { |line| puts "  #{line}" }
      exit 1
    end
  end
end
