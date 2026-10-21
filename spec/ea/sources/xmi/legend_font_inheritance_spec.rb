# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI legend placement font inheritance" do
  include XmiLegendFontInheritanceHelpers
  include LegendSourceDefaultHelpers

  it "renders the saved zero marker using the resolved 7pt font" do
    element = xmi_legend_placement("DUID=FDCEA217;fontsz=0;bold=0;")
    svg = source_default_legend_svg(element: element)

    expect(svg.css("text").first["style"]).to include("font-size:7pt;")
    expect(element.font_size_inherited).to be(true)
    expect(element.font_size).to be_nil
  end

  it "preserves explicit saved sizes and placement geometry" do
    element = xmi_legend_placement("font=Arial;fontsz=120;bold=1;DUID=FDCEA217;")
    svg = source_default_legend_svg(element: element)

    expect(svg.css("text").first["style"]).to include("font-size:12pt;")
    expect([element.font_family, element.font_bold, element.duid]).to eq(["Arial", true, "FDCEA217"])
    expect([element.bounds.x, element.bounds.y, element.bounds.width, element.bounds.height])
      .to eq([78, 32, 186, 95])
  end

  # Native EA draws the items of the nine XMI legends that save no fontsz
  # (1B2D9309, 34FF671B, 6807F4EE, A24E2778, AB281AC1, E9CDAD85, EFBF5F0F,
  # F46E8F19, FEBE5726) at the context size, Cambria 7pt, not 9pt.
  it "inherits the context size when a parsed placement saves no fontsz" do
    element = xmi_legend_placement("DUID=FDCEA217;")
    svg = source_default_legend_svg(element: element)

    expect(svg.css("text").first["style"]).to include("font-size:7pt;")
    expect(element.font_size).to be_nil
  end
end

RSpec.describe "XMI legend inherited font preservation" do
  include XmiLegendFontInheritanceHelpers
  include LegendSourceDefaultHelpers

  it "preserves title styling and shape geometry when inheriting" do
    inherited = source_default_legend_svg(element: xmi_legend_placement("fontsz=0;"))
    unspecified = source_default_legend_svg(element: xmi_legend_placement(""))

    expect(inherited.css("text").last["style"]).to eq(unspecified.css("text").last["style"])
    expect(inherited.css("rect").map(&:to_xml)).to eq(unspecified.css("rect").map(&:to_xml))
    expect(inherited.css("text").map { |node| node["y"] }).to eq(["92.00", "70.00"])
  end
end
