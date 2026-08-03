# frozen_string_literal: true

require "spec_helper"

# Diff Comparator operates on any object exposing `#collections` as a
# hash of array of records. We use a lightweight fake instead of a
# real frozen Ea::Qea::Database so we can mutate the test fixtures.

RSpec.describe Ea::Diff::Comparator do
  # Fake record class. The comparator asks for `primary_key_column`
  # on the class, so we declare it as a class method.
  class FakeRecord
    attr_reader :id, :name

    def self.primary_key_column
      :id
    end

    def initialize(id:, name:)
      @id = id
      @name = name
    end
  end

  def record(id:, name:)
    FakeRecord.new(id: id, name: name)
  end

  # Lightweight fake of Ea::Qea::Database that exposes #collections
  # as a hash of array of records. Used to isolate diff tests from
  # the real frozen Database.
  class FakeDb
    attr_reader :collections

    def initialize(collections)
      @collections = collections
    end

    def self.build(packages:, objects:, attributes:)
      new(packages: packages, objects: objects, attributes: attributes,
          operations: [], connectors: [], diagrams: [])
    end
  end

  def make_db(packages: [], objects: [], attributes: [])
    FakeDb.build(packages: packages, objects: objects, attributes: attributes)
  end

  let(:pkg_a) { record(id: 1, name: "PkgA") }
  let(:pkg_b) { record(id: 2, name: "PkgB") }
  let(:base_db) { make_db(packages: [pkg_a, pkg_b]) }

  describe "identical inputs" do
    it "reports no differences" do
      comparator = described_class.new(base_db, base_db)
      expect(comparator.identical?).to be(true)
      expect(comparator.differences).to eq([])
    end
  end

  describe "added entity" do
    it "reports :added with kind, id, name" do
      new_pkg = record(id: 99, name: "BrandNew")
      new_db = make_db(packages: [pkg_a, pkg_b, new_pkg])

      comparator = described_class.new(base_db, new_db)
      added = comparator.differences.select(&:added?)

      expect(added.size).to eq(1)
      expect(added.first.kind).to eq(:packages)
      expect(added.first.id).to eq(99)
      expect(added.first.name).to eq("BrandNew")
    end
  end

  describe "removed entity" do
    it "reports :removed" do
      new_db = make_db(packages: [pkg_a]) # pkg_b gone
      comparator = described_class.new(base_db, new_db)

      removed = comparator.differences.select(&:removed?)
      expect(removed.size).to eq(1)
      expect(removed.first.id).to eq(2)
      expect(removed.first.name).to eq("PkgB")
    end
  end

  describe "renamed entity (same primary key, different name)" do
    it "reports :renamed with old → new label" do
      renamed_pkg = record(id: 2, name: "PkgBRenamed")
      new_db = make_db(packages: [pkg_a, renamed_pkg])

      comparator = described_class.new(base_db, new_db)
      renamed = comparator.differences.select(&:renamed?)

      expect(renamed.size).to eq(1)
      expect(renamed.first.id).to eq(2)
      expect(renamed.first.name).to include("PkgB")
      expect(renamed.first.name).to include("PkgBRenamed")
    end
  end

  describe "multiple collections in one pass" do
    it "surfaces changes across packages, objects, attributes" do
      old_db = make_db(
        packages: [pkg_a],
        objects: [record(id: 10, name: "OldObj")],
        attributes: []
      )
      new_db = make_db(
        packages: [pkg_a],
        objects: [record(id: 10, name: "NewObj"), record(id: 11, name: "AddObj")],
        attributes: [record(id: 100, name: "NewAttr")]
      )

      comparator = described_class.new(old_db, new_db)
      kinds = comparator.differences.map(&:kind).uniq.sort
      expect(kinds).to eq(%i[attributes objects])

      renamed_obj = comparator.differences.find(&:renamed?)
      expect(renamed_obj.name).to include("OldObj")
      expect(renamed_obj.name).to include("NewObj")
    end
  end
end
