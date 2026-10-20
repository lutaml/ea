# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI saved object font inheritance" do
  include XmiObjectFontHelpers

  it "inherits the object family and GDI-normalized size for a zero placement" do
    with_xmi_object_font("font=Yu Gothic UI;fontsz=100;") do |builder|
      element = xmi_object_font_placement(builder, "fontsz=0;")

      expect([element.font_family, element.font_size, element.font_logical_height])
        .to eq(["Yu Gothic UI", 9, 13])
      expect([element.bounds.x, element.bounds.y, element.bounds.width, element.bounds.height])
        .to eq([78, 32, 186, 95])
    end
  end

  it "inherits omitted placement fields independently" do
    with_xmi_object_font("font=Yu Gothic UI;fontsz=100;") do |builder|
      family = xmi_object_font_placement(builder, "font=Arial;")
      size = xmi_object_font_placement(builder, "fontsz=120;")

      expect([family.font_family, family.font_size]).to eq(["Arial", 9])
      expect([size.font_family, size.font_size]).to eq(["Yu Gothic UI", 12])
    end
  end
end

RSpec.describe "XMI saved object font preservation" do
  include XmiObjectFontHelpers

  it "preserves explicit placement fonts and style controls" do
    with_xmi_object_font("font=Yu Gothic UI;fontsz=100;") do |builder|
      element = xmi_object_font_placement(builder, "font=Arial;fontsz=120;bold=1;DUID=FDCEA217;")

      expect([element.font_family, element.font_size, element.font_logical_height]).to eq(["Arial", 12, 16])
      expect([element.font_bold, element.duid]).to eq([true, "FDCEA217"])
    end
  end

  it "keeps theme inheritance when neither source saves an explicit font" do
    with_xmi_object_font("fontsz=0;") do |builder|
      element = xmi_object_font_placement(builder, "fontsz=0;")

      expect([element.font_family, element.font_size, element.font_logical_height]).to eq([nil, nil, nil])
      expect(element.font_size_inherited).to be(true)
    end
  end
end
