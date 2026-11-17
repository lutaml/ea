# frozen_string_literal: true

require "spec_helper"
require "yaml"

# Native exports: lutaml/lutaml@063ca187, examples/xmi/Images/<EAID>.svg.
# Regenerate baseline.yml with svg:parity_report using the manifest model and refs/.
RSpec.describe "Committed EA reference parity gate" do # rubocop:disable Metrics/BlockLength
  let(:root) { File.expand_path("../../../..", __dir__) }
  let(:fixture_dir) { File.join(root, "spec/fixtures/parity") }
  let(:ref_dir) { File.join(fixture_dir, "refs") }
  let(:manifest) { YAML.safe_load_file(File.join(fixture_dir, "manifest.yml")) }
  let(:entries) { manifest.fetch("diagrams") }
  let(:ids) do
    entries.map { |entry| Ea::Sources::Qea::IdNormalizer.from_guid(entry.fetch("guid")) }
  end
  let(:baseline) { YAML.safe_load_file(File.join(fixture_dir, "baseline.yml")) }
  let(:rows) { baseline.fetch("diagrams") }
  let(:document) do
    Ea::Svg::Parity::Source.new(File.join(root, manifest.fetch("model"))).load
  end
  let(:suite) { Ea::Svg::Parity::Suite.new(document, ref_dir).measure }

  it "has a committed reference for every manifest diagram" do
    expect(entries).not_to be_empty
    entries.each do |entry|
      path = File.join(ref_dir, "#{entry.fetch("eaid")}.svg")
      expect(File).to exist(path), "Missing EA reference: #{path}"
    end
  end

  it "measures every manifest diagram and records each exactly once in the baseline" do
    expect(suite.per_diagram.map(&:id)).to match_array(ids)
    expect(rows.map { |row| row.fetch("id") }).to match_array(ids)
  end

  it "does not increase any diagram delta count and reports baseline shrinkage" do
    expected = rows.to_h { |row| [row.fetch("id"), row.fetch("deltas")] }

    aggregate_failures do
      suite.per_diagram.each do |diagram|
        counts = diagram.delta_summary.transform_keys(&:to_s)
        limits = expected.fetch(diagram.id)
        expect(counts.keys).to match_array(limits.keys)
        counts.each do |key, count|
          limit = limits.fetch(key)
          label = "#{diagram.id} (#{diagram.name}) #{key}"
          expect(limit).to be_a(Integer)
          expect(limit).to be >= 0
          expect(count).to be <= limit, "#{label} increased: baseline=#{limit}, actual=#{count}"
          warn "Parity baseline can tighten: #{label} #{limit} -> #{count}" if count < limit
        end
      end
    end
  end
end
