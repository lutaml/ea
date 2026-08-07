# frozen_string_literal: true

require "spec_helper"
require "ea/mdg"

RSpec.describe Ea::Mdg::Registry do
  describe ".from_paths" do
    let(:mdg_file) { fixtures_path("mdg/CityGML_MDG_Technology.xml") }

    # Registration also lands in Lutaml::Model::GlobalRegister — sweep
    # it so examples stay order-independent.
    def with_registry(paths)
      registry = described_class.from_paths(paths)
      yield registry
    ensure
      registry&.documents&.map(&:technology_name)&.each { |name| registry.unregister(name) }
    end

    it "registers each loadable MDG file" do
      with_registry([mdg_file]) do |registry|
        expect(registry.documents.size).to eq(1)
      end
    end

    it "expands directories recursively" do
      with_registry([File.dirname(mdg_file)]) do |registry|
        expect(registry.documents.size).to be >= 1
      end
    end

    it "skips unloadable paths without raising" do
      with_registry(["/nonexistent/mdg.xml"]) do |registry|
        expect(registry.documents).to be_empty
      end
    end
  end
end
