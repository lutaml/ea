# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Diff::Comparator do
  class FakeRecord
    def self.primary_key_column
      :id
    end

    attr_reader :id, :name, :type

    def initialize(id:, name:, type: "Class")
      @id = id
      @name = name
      @type = type
    end

    def to_hash
      { "id" => id, "name" => name, "type" => type }
    end
  end

  class FakeDb
    attr_reader :collections

    def initialize(collections)
      @collections = collections
    end
  end

  def make_db(packages: [], objects: [], attributes: [])
    FakeDb.new(
      packages: packages,
      objects: objects,
      attributes: attributes,
      operations: [],
      connectors: [],
      diagrams: []
    )
  end

  let(:obj_a) { FakeRecord.new(id: 1, name: "Foo", type: "Class") }
  let(:base_db) { make_db(objects: [obj_a]) }

  describe "modified detection" do
    it "flags a :modified change when type differs but id+name are same" do
      modified = FakeRecord.new(id: 1, name: "Foo", type: "Interface")
      new_db = make_db(objects: [modified])

      comparator = described_class.new(base_db, new_db)
      mods = comparator.differences.select(&:modified?)

      expect(mods.size).to eq(1)
      expect(mods.first.kind).to eq(:objects)
      expect(mods.first.details).to include("type")
    end

    it "does not flag unchanged records" do
      identical = FakeRecord.new(id: 1, name: "Foo", type: "Class")
      new_db = make_db(objects: [identical])

      comparator = described_class.new(base_db, new_db)
      mods = comparator.differences.select(&:modified?)
      expect(mods).to be_empty
    end

    it "includes up to 5 changed field names in name, all in details" do
      big_record_class = Class.new do
        def self.primary_key_column
          :id
        end

        attr_reader :id, :name

        def initialize(id, name, values)
          @id = id
          @name = name
          @values = values
        end

        def to_hash
          @values.merge("id" => @id, "name" => @name)
        end
      end

      old_rec = big_record_class.new(1, "X", "a" => 1, "b" => 2, "c" => 3, "d" => 4, "e" => 5, "f" => 6)
      new_rec = big_record_class.new(1, "X", "a" => 9, "b" => 9, "c" => 9, "d" => 9, "e" => 9, "f" => 9)
      old_db = make_db(objects: [old_rec])
      new_db = make_db(objects: [new_rec])

      comparator = described_class.new(old_db, new_db)
      mod = comparator.differences.find(&:modified?)
      expect(mod.details.size).to eq(6)
      expect(mod.name.split(", ").size).to eq(5)
    end
  end
end
