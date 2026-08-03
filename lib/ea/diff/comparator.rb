# frozen_string_literal: true

module Ea
  module Diff
    # Compares two Ea::Qea::Database instances and produces a list of
    # structural changes. Identity is keyed by primary-key value within
    # each collection; renaming surfaces as :removed + :added unless the
    # name change happens with the same PK (then it's :renamed).
    #
    # OCP: new entity types are added by registering a comparator entry
    # in COLLECTIONS, not by modifying this class.
    class Comparator
      attr_reader :old_db, :new_db, :differences

      # Each entry maps a collection name to the attribute used as the
      # human-readable label. Add new collections here without touching
      # the diff algorithm.
      COLLECTIONS = {
        packages: :name,
        objects: :name,
        attributes: :name,
        operations: :name,
        connectors: :name,
        diagrams: :name
      }.freeze

      def initialize(old_db, new_db)
        @old_db = old_db
        @new_db = new_db
        @differences = []
        compare_all
      end

      def identical?
        @differences.empty?
      end

      private

      def compare_all
        COLLECTIONS.each do |collection, label_attr|
          compare_collection(collection, label_attr)
        end
      end

      def compare_collection(name, label_attr)
        old_records = index_by_id(old_db, name, label_attr)
        new_records = index_by_id(new_db, name, label_attr)

        old_records.each do |id, old_entry|
          new_entry = new_records.delete(id)
          if new_entry.nil?
            add(:removed, name, id, old_entry[:label])
          elsif new_entry[:label] != old_entry[:label]
            add(:renamed, name, id, "#{old_entry[:label]} → #{new_entry[:label]}")
          else
            compare_modifications(name, id, old_entry[:record], new_entry[:record])
          end
        end

        new_records.each_value do |entry|
          add(:added, name, entry[:id], entry[:label])
        end
      end

      # Compares two records of the same type by their to_hash
      # representation. If they differ beyond identity (id and the
      # label attribute), emit a :modified change with a list of
      # the differing field names in #details.
      def compare_modifications(collection, id, old_record, new_record)
        old_hash = old_record.to_hash
        new_hash = new_record.to_hash
        changed = []
        (old_hash.keys | new_hash.keys).each do |key|
          next if key == "record_type"

          old_val = old_hash[key]
          new_val = new_hash[key]
          next if old_val == new_val

          changed << key
        end
        return if changed.empty?

        @differences << Change.new(change: :modified, kind: collection,
                                   id: id, name: changed.first(5).join(", "),
                                   details: changed)
      end

      def index_by_id(db, collection_name, label_attr)
        records = db.collections[collection_name] || []
        records.each_with_object({}) do |record, acc|
          id = record.public_send(record.class.primary_key_column)
          next if id.nil?

          acc[id] = {
            id: id,
            label: record.public_send(label_attr).to_s,
            record: record
          }
        end
      end

      def add(change, kind, id, name)
        @differences << Change.new(change: change, kind: kind, id: id, name: name)
      end
    end
  end
end
