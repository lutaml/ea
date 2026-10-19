# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Theme::Definition, "attribute content seats" do
  it "separates the inherited attribute seat from the legacy enum spec" do
    [Ea::Theme::Registry.default, Ea::Theme::Registry.lookup("39")].each do |theme|
      expect(theme.attribute_content_x_offset).to eq(22)
      expect(theme.attribute_spec.content_x_offset).to eq(20)
      expect(theme.to_h[:attribute_spec]).to be_nil
      expect(described_class.new(**theme.to_h).attribute_content_x_offset).to eq(22)
      expect(theme.with(font_family: "Arial").attribute_content_x_offset).to eq(22)
    end
  end
end

RSpec.describe Ea::Theme::Definition, "explicit attribute content seats" do
  it "preserves explicit offsets through copying and reconstruction" do
    [20, 40, 22, nil].each do |offset|
      spec = described_class::AttrSpec.new(visibility_x_offset: 5, content_x_offset: offset)
      theme = described_class.new(id: "custom", attribute_spec: spec)
      copies = [theme, theme.with(font_family: "Arial"), described_class.new(**theme.to_h)]

      copies.each do |copy|
        expect(copy.attribute_content_x_offset).to eq(offset)
        expect(copy.to_h[:attribute_spec]).to eq(spec)
        expect(copy.attribute_spec.content_x_offset).to eq(offset)
      end
      expect(theme.with(attribute_spec: nil).attribute_content_x_offset).to eq(22)
      expect(theme.with(attribute_spec: nil).attribute_spec.content_x_offset).to eq(20)
    end
  end

  it "lets a copied inherited theme acquire an explicit override" do
    spec = described_class::AttrSpec.new(visibility_x_offset: 5, content_x_offset: 40)
    theme = Ea::Theme::Registry.default.with(attribute_spec: spec)

    expect(theme.attribute_content_x_offset).to eq(40)
    expect(described_class.new(**theme.to_h).attribute_content_x_offset).to eq(40)
    expect(Ea::Theme::Registry.lookup("119").attribute_content_x_offset).to eq(22)
  end
end
