# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Sources::Qea::PropertyBuilder do
  # Row-shaped Struct matching the t_attribute columns build_one
  # reads; a nil database is fine because build_one never queries it.
  AttrRow = Struct.new(:name, :type, :default, :scope, :stereotype, :lowerbound,
                       :upperbound, :isordered, :allowduplicates,
                       :derived, :notes, :ea_guid, keyword_init: true)
  OwnerObject = Struct.new(:name, :ea_guid, :ea_object_id,
                           keyword_init: true)

  let(:owner) do
    OwnerObject.new(name: "GM_GriddedSurface",
                    ea_guid: "{11111111-2222-3333-4444-555555555555}",
                    ea_object_id: 1)
  end

  let(:builder) { described_class.new(nil) }

  def row(overrides = {})
    AttrRow.new(
      name: "columns", type: "Integer", default: "", scope: "Public",
      stereotype: "", lowerbound: "1", upperbound: "1", isordered: "0",
      allowduplicates: "0", derived: "0", notes: "",
      ea_guid: "{aaaaaaaa-bbbb-cccc-dddd-000000000001}",
      **overrides
    )
  end

  it "maps the t_attribute Derived column onto is_derived" do
    # 096AF2FD/GM_GriddedSurface: /columns and /rows render with the
    # derived slash, controlPoint does not.
    derived = builder.build_one(row(derived: "1"), owner)
    plain = builder.build_one(row, owner)
    expect(derived.is_derived).to be(true)
    expect(plain.is_derived).to be(false)
  end
end
