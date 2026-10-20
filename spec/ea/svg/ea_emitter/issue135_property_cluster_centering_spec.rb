# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Issue 135 centered source Property clusters through QEA" do
  include QeaEndLabelHelpers
  include Issue135PropertyClusterHelpers

  it "seats diagram 25 connector 139 relative to its source outline" do
    texts = issue135_property_cluster(role: "extent", type: "Aggregation",
                                      source: [810, 380, 111, 70], target: [420, 380, 270, 71],
                                      geometry: issue135_property_cluster_geometry(25))

    expect(texts).to include({ text: "+extent", x: -84, y: -21 },
                             { text: "«property»", x: -92, y: -9 })
  end

  it "seats diagram 89 connector 889 relative to its source outline" do
    texts = issue135_property_cluster(role: "target", target_border: 2,
                                      source: [274, 47, 330, 142], target: [296, 252, 287, 465],
                                      geometry: issue135_property_cluster_geometry(89))

    expect(texts).to include({ text: "+target", x: 320, y: 166 },
                             { text: "«property»", x: 311, y: 178 })
  end

  it "seats diagram 117 connector 273 relative to its source outline" do
    texts = issue135_property_cluster(role: "lod0MultiCurve", target_border: 2,
                                      source: [703, 177, 190, 80], target: [320, 20, 269, 387],
                                      geometry: issue135_property_cluster_geometry(117))

    expect(texts).to include({ text: "+lod0MultiCurve", x: -74, y: 4 },
                             { text: "«property»", x: -60, y: 16 })
  end
end

RSpec.describe "Issue 135 Property cluster box presentation" do
  include QeaEndLabelHelpers
  include Issue135PropertyClusterHelpers

  it "preserves left alignment" do
    texts = issue135_property_cluster_control(**{ box: { "alignment" => 0 } })

    expect(texts).to eq([{ text: "+extent", x: 409.0, y: 257.0 },
                         { text: "«property»", x: 409.0, y: 269.0 }])
  end

  it "preserves single-line-height boxes" do
    texts = issue135_property_cluster_control(**{ box: { "cy" => 18 } })

    expect(texts).to eq([{ text: "+extent", x: 409.0, y: 257.0 },
                         { text: "«property»", x: 401.0, y: 269.0 }])
  end

  it "preserves bold boxes" do
    texts = issue135_property_cluster_control(**{ box: { "bold" => true } })

    expect(texts).to eq([{ text: "+extent", x: 502.0, y: 336.0 },
                         { text: "«property»", x: 494.0, y: 349.0 }])
  end

  it "preserves rotated boxes" do
    texts = issue135_property_cluster_control(**{ box: { "rotation" => 1 } })

    expect(texts).to eq([{ text: "+extent", x: 502.0, y: 336.0 },
                         { text: "«property»", x: 494.0, y: 349.0 }])
  end
end

RSpec.describe "Issue 135 Property cluster neighboring label contracts" do
  include QeaEndLabelHelpers
  include Issue135PropertyClusterHelpers

  it "preserves plain source labels" do
    texts = issue135_property_cluster_control(**{ stereotype: "" })

    expect(texts).to eq([{ text: "+extent", x: 502.0, y: 336.0 }])
  end

  it "preserves other stereotypes" do
    texts = issue135_property_cluster_control(**{ stereotype: "Type" })

    expect(texts).to eq([{ text: "+extent", x: 502.0, y: 336.0 },
                         { text: "«Type»", x: 503.0, y: 348.0 }])
  end

  it "preserves unsupported routes" do
    texts = issue135_property_cluster_control(**{ style: { mode: "9", lwidth: "9" } })

    expect(texts).to eq([{ text: "+extent", x: 502.0, y: 336.0 },
                         { text: "«property»", x: 494.0, y: 348.0 }])
  end
end

RSpec.describe "Issue 135 Property cluster typography" do
  include QeaEndLabelHelpers
  include Issue135PropertyClusterHelpers

  it "preserves other font families" do
    texts = issue135_property_cluster_control(**{ family: "Arial" })

    expect(texts).to eq([{ text: "+extent", x: 502.0, y: 336.0 },
                         { text: "«property»", x: 494.0, y: 348.0 }])
  end

  it "preserves other font sizes" do
    texts = issue135_property_cluster_control(**{ size: 8 })

    expect(texts).to eq([{ text: "+extent", x: 502.0, y: 336.0 },
                         { text: "«property»", x: 495.0, y: 350.0 }])
  end

  it "preserves bold typography" do
    texts = issue135_property_cluster_control(**{ weight: 700 })

    expect(texts).to eq([{ text: "+extent", x: 409.0, y: 257.0 },
                         { text: "«property»", x: 401.0, y: 269.0 }])
  end

  it "preserves italic typography" do
    texts = issue135_property_cluster_control(**{ font_style: "italic" })

    expect(texts).to eq([{ text: "+extent", x: 409.0, y: 257.0 },
                         { text: "«property»", x: 401.0, y: 269.0 }])
  end
end

RSpec.describe "Issue 135 Property cluster supported directions and casing" do
  include QeaEndLabelHelpers
  include Issue135PropertyClusterHelpers

  it "preserves upward short-role placement" do
    texts = issue135_property_cluster_control(heading: [0, -1])

    expect(texts).to eq([{ text: "+extent", x: 409, y: 258 },
                         { text: "«property»", x: 401, y: 270 }])
  end

  it "preserves rightward short-role placement" do
    texts = issue135_property_cluster_control(heading: [1, 0], style: { mode: "3", lwidth: "2", tree: "H" })

    expect(texts).to eq([{ text: "+extent", x: 595, y: 257 },
                         { text: "«property»", x: 587, y: 269 }])
  end

  it "centers using the end stereotype's stored spelling" do
    texts = issue135_property_cluster_control(stereotype: "Property")

    expect(texts).to eq([{ text: "+extent", x: 417, y: 257 },
                         { text: "«Property»", x: 409, y: 269 }])
  end
end

RSpec.describe "Issue 135 right-seat Property role centering" do
  include QeaEndLabelHelpers
  include Issue135PropertyClusterHelpers

  let(:box) { { "ox" => 26, "oy" => -27, "cy" => 31, "alignment" => 1 } }

  def role_x(role, **options)
    texts = issue135_property_cluster_control(role: role, heading: [1, 0], box: box, **options)
    texts.find { |text| text[:text] == "+#{role}" }[:x]
  end

  it "centers a short role under the Property line (diagram 54 connector 892)" do
    expect(role_x("district")).to eq(535.0)
  end

  it "centers a short role under the Property line (diagram 146 connector 629)" do
    expect(role_x("opening")).to eq(532.0)
  end

  it "keeps roles as wide as the Property line at the plain seat" do
    expect([role_x("boundary"), role_x("trafficArea")]).to eq([529.0, 529.0])
  end

  it "keeps plain source roles at the plain seat" do
    expect(role_x("district", stereotype: "")).to eq(529.0)
  end

  it "keeps other box heights at the plain seat" do
    expect(role_x("district", box: box.merge("cy" => 18))).to eq(529.0)
  end
end
