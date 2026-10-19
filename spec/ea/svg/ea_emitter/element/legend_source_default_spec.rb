# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Legend source default font markers" do
  include LegendSourceDefaultHelpers

  it "inherits the resolved size for an explicit source use-default marker" do
    element = Ea::Model::DiagramElement.new(style: { fontsz: "0" })
    svg = source_default_legend_svg(element: element)

    expect(svg.css("text").first["style"]).to include("font-size:7pt;")
    expect(svg.css("text").last["style"]).to include("font-size:12pt;", "font-weight:700;")
    expect(svg.css("rect").map { |node| node.attributes.transform_values(&:value) }).to eq(
      source_default_legend_svg(element: Ea::Model::DiagramElement.new)
        .css("rect").map { |node| node.attributes.transform_values(&:value) }
    )
    expect(svg.css("text").map { |node| node["y"] }).to eq(["92.00", "70.00"])
  end

  it "preserves the resolved size unit and explicit effective font size" do
    inherited = source_default_legend_svg(element: Ea::Model::DiagramElement.new(style: { fontsz: 0 }),
                                          size: 11, unit: "px")
    explicit = source_default_legend_svg(
      element: Ea::Model::DiagramElement.new(font_size_inherited: true, font_size: 10), unit: "px"
    )

    expect(inherited.css("text").first["style"]).to include("font-size:11px;")
    expect(explicit.css("text").first["style"]).to include("font-size:10px;")
    expect(inherited.css("text").last["style"]).to include("font-size:12pt;")
  end
end

RSpec.describe "Legend defaults without source markers" do
  include LegendSourceDefaultHelpers

  it "retains the 9pt default without a saved zero marker" do
    [{}, { fontsz: nil }, { fontsz: "" }, { fontsz: "90" }].each do |style|
      [nil, 0].each do |size|
        svg = source_default_legend_svg(element: Ea::Model::DiagramElement.new(style: style, font_size: size))
        expect(svg.css("text").first["style"]).to include("font-size:9pt;")
      end
    end
  end
end

RSpec.describe "QEA legend source defaults" do
  include LegendSourceDefaultHelpers
  include QeaCompartmentFontHelpers

  it "preserves explicit saved sizes through QEA" do
    document = public_compartment_document
    [
      %w[0016F797-D055-4717-AF1A-606413D0A166 4E5A37CB-F6FA-44ea-8762-5F379CFFB6A2 90],
      %w[227300E2-4F4B-4955-83B9-FA626CE8680B CEA68306-BC83-4809-A89A-9B9E7D45776D 100]
    ].each do |diagram_id, object_id, marker|
      placement, labels = source_default_qea_legend(document, diagram_id, object_id)

      expect(placement.style[:fontsz]).to eq(marker)
      expect(labels.map { |node| node["style"] }).to all(include("font-size:9pt;"))
    end
  end
end

RSpec.describe "QEA legend zero marker inheritance" do
  include LegendSourceDefaultHelpers
  include QeaCompartmentFontHelpers

  it "renders the source zero marker as 7pt through the public QEA emitter" do
    document = public_compartment_document
    placement, labels = source_default_qea_legend(document, "00C5C772-5A03-434f-BF30-AC37542A1AAC",
                                                  "CEA68306-BC83-4809-A89A-9B9E7D45776D")

    expect(placement.style.fetch(:fontsz)).to eq("0")
    expect(labels.map { |node| node["style"] }).to all(include("font-size:7pt;", "font-family:Cambria;"))
  end
end

RSpec.describe "QEA legend missing size inheritance" do
  include LegendSourceDefaultHelpers
  include QeaCompartmentFontHelpers

  it "inherits 7pt for source defaults on both saved legend classifiers" do
    document = public_compartment_document
    [
      %w[E9CDAD85-ECF1-43de-819F-30A0D01785E6 CEA68306-BC83-4809-A89A-9B9E7D45776D],
      %w[A24E2778-5AD9-44f2-AB8F-5CD3913477D6 4E5A37CB-F6FA-44ea-8762-5F379CFFB6A2]
    ].each do |diagram_id, object_id|
      placement, labels = source_default_qea_legend(document, diagram_id, object_id)

      expect(placement.style).not_to have_key(:fontsz)
      expect(labels.map { |node| node["style"] }).to all(include("font-size:7pt;", "font-family:Cambria;"))
    end
  end
end

RSpec.describe "Legend source inheritance units" do
  include LegendSourceDefaultHelpers

  it "uses the resolved inherited size and unit without imposing a corpus size" do
    svg = source_default_legend_svg(element: Ea::Model::DiagramElement.new(font_size_inherited: true),
                                    size: 11, unit: "px")

    expect(svg.css("text").first["style"]).to include("font-size:11px;")
    expect(svg.css("text").last["style"]).to include("font-size:12pt;")
  end
end
