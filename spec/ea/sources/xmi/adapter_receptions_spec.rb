# frozen_string_literal: true

require "spec_helper"
require "xmi"

RSpec.describe Ea::Sources::Xmi::Adapter do
  include XmiReceptionHelpers

  it "attaches source receptions to their owners while preserving ordinary operations" do
    path = fixtures_path("basic.xmi")
    root = Xmi::Sparx::Root.parse_xml(File.read(path))
    document = described_class.new(root, path).to_document
    operations = document.classifiers.flat_map(&:operations)
    receptions = operations.select(&:is_reception)

    expect(receptions.map { |operation| [operation.owner_id, operation.id, operation.name] })
      .to match_array(reception_source_contracts)
    expect(operations.reject(&:is_reception).size).to eq(12)
  end
end
