# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Xmi::LookupService do
  let(:fixture_path) { fixtures_path("associationclass.xmi") }
  let(:xmi_model) { Xmi::Sparx::Root.parse_xml(File.read(fixture_path)) }
  let(:parser) { Ea::Xmi::Parser.new.tap { |p| p.parse(xmi_model) } }
  let(:lookup) { described_class.new(parser) }

  # Regression for #234: build_dependency_index referenced a bare
  # `parser` local (missing @), raising NameError the first time the
  # dependency lookups ran — the Liquid-drops path that shipped in
  # 0.6.151 without spec coverage.
  describe "#select_dependencies_by_supplier" do
    it "returns [] instead of raising for ids with no dependencies" do
      expect(lookup.select_dependencies_by_supplier("EAID_NONE")).to eq([])
      expect(lookup.select_dependencies_by_client("EAID_NONE")).to eq([])
    end
  end

  describe "drops integration" do
    it "builds class drops through serialize_to_liquid without raising" do
      drops = parser.serialize_to_liquid(xmi_model)
      klasses = []
      walk = lambda do |packages|
        packages.each do |pkg|
          klasses.concat(pkg.klasses)
          walk.call(pkg.children_packages)
        end
      end
      walk.call(drops.packages)
      expect(klasses.map(&:name)).to include("ClassA", "ClassB")
    end
  end
end
