# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI placement font source contracts" do
  let(:path) { fixtures_path("issue135_38170608_placement_fonts.xmi") }
  let(:root) { Xmi::Sparx::Root.parse_xml(File.read(path)) }
  let(:diagram) { Ea::Sources::Xmi::DiagramBuilder.new(root, path).build_all.first }

  it "preserves point units and explicit GDI heights from the Plateau placement styles" do
    explicit = diagram.elements.select(&:font_size)

    expect(explicit.map(&:duid)).to contain_exactly("275D522C", "3EEC9DB6")
    explicit.each do |element|
      expect([element.font_family, element.font_size, element.font_size_unit,
              element.font_logical_height, element.font_size_inherited])
        .to eq(["Yu Gothic UI", 9, "pt", 13, false])
    end
  end

  it "inherits missing and zero sizes without manufacturing a classifier font" do
    inherited = diagram.elements.reject(&:font_size)

    expect(inherited.map(&:duid)).to include("378A485C", "83ADBA37")
    expect(inherited.size).to eq(8)
    expect(inherited.find { |element| element.duid == "378A485C" }.font_size_inherited).to be(false)
    expect(inherited.find { |element| element.duid == "83ADBA37" }.font_size_inherited).to be(true)
    inherited.each do |element|
      expect([element.font_family, element.font_size, element.font_logical_height,
              element.font_size_unit])
        .to eq([nil, nil, nil, "pt"])
    end
  end
end

RSpec.describe "XMI source font resolution" do
  let(:path) { fixtures_path("issue135_38170608_placement_fonts.xmi") }
  let(:root) { Xmi::Sparx::Root.parse_xml(File.read(path)) }
  let(:diagram) { Ea::Sources::Xmi::DiagramBuilder.new(root, path).build_all.first }

  it "passes saved logical heights to the font resolver independently of the theme unit" do
    resolver = Ea::Svg::EaEmitter::FontResolver.new(
      diagram, theme: Ea::Theme::Definition.new(id: "pixel-theme", font_size_unit: "px")
    )
    explicit = diagram.elements.find { |element| element.duid == "275D522C" }
    inherited = diagram.elements.find { |element| element.duid == "83ADBA37" }

    expect([resolver.size_for(explicit), resolver.size_unit_for(explicit),
            resolver.logical_height_for(explicit)]).to eq([9, "pt", 13])
    expect([resolver.size_for(inherited), resolver.logical_height_for(inherited)])
      .to eq([7, nil])
  end
end
