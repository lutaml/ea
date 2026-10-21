# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Compact class header geometry" do
  include CompactHeaderRuleHelpers

  it "seats basic attribute headers above their unchanged attribute rows" do
    context = compact_source_context("basic", "4F421236", "Class A")
    expect(context.header_lines).to eq([["Class A", :bold]])
    expect(context.attr_lines).to eq(["- Attribute A: int", "- Attribute B: int"])
    expect([context.geometry.header_first_y, context.geometry.divider_y,
            context.geometry.attr_first_y, context.geometry.attr_bottom_y].map { |y| y - context.bounds.y })
      .to eq([19, 26, 40, 52])
  end

  it "seats the divider of a ghost-led header 7 below its last baseline" do
    context = compact_source_context("20251010_current_plateau_v5.1", "0114FD24", "AbstractConstruction")
    expect(context.header_lines.first).to eq(["_CityObject", :italic])
    expect(context.geometry.divider_y - context.bounds.y).to eq(50)
    expect(context.geometry.attr_first_y - context.bounds.y).to eq(64)
  end

  it "seats an independent stereotype header above unchanged source attributes" do
    context = compact_source_context("20251010_current_plateau_v5.1", "0016F797", "KeyValuePairAttribute")
    expect(context.header_lines).to eq([["«DataType»", :normal], ["uro::KeyValuePairAttribute", :bold]])
    expect(context.attr_lines).to eq(["+ key: gml:CodeType", "+ codeValue: gml:CodeType"])
    expect([context.geometry.header_first_y, context.geometry.divider_y,
            context.geometry.attr_first_y, context.geometry.attr_bottom_y]).to eq([548, 567, 581, 593])
  end
end

RSpec.describe "Compact header operation anchors" do
  include CompactHeaderRuleHelpers

  it "anchors operation-only rows to the header and attribute-based operations to their divider" do
    operations = compact_source_context("basic", "2AAB709F", "Class A")
    combined = compact_source_context("basic", "D2FA55D3", "Class A")
    expect(operations.op_lines).to eq(["+ Operation A(int): void", "+ Operation B(int): void"])
    expect([operations.geometry.divider_y, operations.geometry.op_first_y].map { |y| y - operations.bounds.y })
      .to eq([26, 40])
    expect([combined.geometry.attr_first_y, combined.geometry.attr_bottom_y,
            combined.geometry.op_divider_y, combined.geometry.op_first_y].map { |y| y - combined.bounds.y })
      .to eq([40, 52, 58, 72])
  end
end

RSpec.describe "Compact header preservation" do
  include CompactHeaderRuleHelpers

  it "applies the compact offsets to an italic ghost-led header" do
    geometry = compact_geometry_control({ header_lines: [["Parent", :italic], ["Example", :bold]] })
    expect([geometry.divider_offset, geometry.attr_first_offset]).to eq([7, 8])
  end

  it "keeps unsupported fonts, units, logical cells and header forms on their existing offsets" do
    controls = [
      { family: "Carlito" }, { family: "Carlito", size: 9 }, { size: 9 }, { size_unit: "px" },
      { logical_height: 10 }, { classifier: Ea::Model::Interface.new(id: "interface") },
      { classifier: Ea::Model::Enumeration.new(id: "enum") },
      { header_lines: [["Parent", :italic_tight], ["Example", :bold]] },
      { marker_count: 1 }, { enum_literals_count: 1 }, { attr_lines: ["«Property»", "+ value: int"] }
    ]
    controls.each do |options|
      geometry = compact_geometry_control(options)
      expected_divider = options[:classifier].is_a?(Ea::Model::Interface) ? 9 : 8
      expected_attr = options[:attr_lines] ? 11 : 7
      expect([geometry.divider_offset, geometry.attr_first_offset]).to eq([expected_divider, expected_attr])
    end
  end
end

RSpec.describe "Custom compact header offsets" do
  include CompactHeaderRuleHelpers

  it "preserves custom divider and line offsets" do
    [{ divider_offset: 10 }, { header_line_offset: 8 }, { attr_line_offset: 8 }].each do |offsets|
      compartments = Ea::Theme::Definition::CompartmentSpec.new(
        **Ea::Theme::Definition::DEFAULT_COMPARTMENTS.to_h.merge(offsets)
      )
      geometry = compact_geometry_control(compartments: compartments)
      expect([geometry.divider_offset, geometry.attr_first_offset])
        .to eq([offsets.fetch(:divider_offset, 8), 7])
    end
  end
end
