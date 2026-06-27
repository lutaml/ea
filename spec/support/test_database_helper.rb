# frozen_string_literal: true

module TestDatabaseHelper
  # Build a minimal Database with real collections for transformer specs
  def build_test_database(collections = {})
    db = Ea::Qea::Database.new("test.qea")
    default_collections = {
      objects: [],
      attributes: [],
      operations: [],
      operation_params: [],
      connectors: [],
      packages: [],
      diagrams: [],
      diagram_objects: [],
      diagram_links: [],
      object_constraints: [],
      tagged_values: [],
      object_properties: [],
      attribute_tags: [],
      xrefs: [],
      documents: [],
      scripts: [],
      stereotypes: [],
      datatypes: [],
      constraint_types: [],
      connector_types: [],
      diagram_types: [],
      object_types: [],
      status_types: [],
      complexity_types: [],
    }
    default_collections.merge(collections).each do |name, records|
      db.add_collection(name, records)
    end
    db
  end
end

RSpec.configure do |config|
  config.include TestDatabaseHelper
end
