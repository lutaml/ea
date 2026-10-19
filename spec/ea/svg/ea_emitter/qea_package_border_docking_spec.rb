# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA package import border docking" do
  include QeaPackageTabWidthHelpers

  let(:document) { package_width_document("20251010_current_plateau_v5.1") }
  include PackageBorderDockingHelpers

  let(:emitters) { package_border_emitters(document) }

  it "seats both import routes and arrowheads on the outer package borders", :aggregate_failures do
    {
      "B0802E45-AF95-433a-BA7A-93EB62945730" => ["M 146 291 L 228 390", "M 215 382 L 228 390 L 222 375"],
      "7BAEBE89-B43D-46dc-971B-4803FA14CDE5" => ["M 369 291 L 299 390", "M 304 375 L 299 390 L 312 381"]
    }.each do |ref, (route, marker)|
      expect(package_border_geometry(emitters, ref)).to eq([route, marker])
    end
  end

  it "preserves the three neighboring Dependency routes and arrowheads" do
    {
      "8F6BFB6E-4246-46f5-A6B7-A5DAB33B520F" => ["M 216 131 L 148 209", "M 154 194 L 148 209 L 162 201"],
      "C928AE98-62FD-487e-9CDA-37875A5449D4" => ["M 298 131 L 360 199", "M 346 191 L 360 199 L 354 185"],
      "604544F9-149D-40f0-80CE-FCAC7CED4532" => ["M 324 246 L 190 248", "M 205 243 L 190 248 L 205 253"]
    }.each do |ref, (route, marker)|
      expect(package_border_geometry(emitters, ref)).to eq([route, marker])
    end
  end
end

RSpec.describe "Package border docking guards" do
  include QeaRoutingHelpers

  let(:thin) do
    { connector_type: "Package", source: [724, 563, 384, 64], target: [761, 1, 312, 465],
      path: nil, geometry: "EDGE=1;", style: "Mode=3;LWidth=0;" }
  end

  it "preserves thin packages without two borders, tree routes and other connector widths" do
    [
      [thin, [nil, nil]],
      [thin, ["LWth=2;", nil]],
      [thin.merge(style: "Mode=3;LWidth=0;TREE=V;"), ["LWth=2;", "LWth=2;"]],
      [thin.merge(style: "Mode=3;LWidth=1;"), ["LWth=2;", "LWth=2;"]]
    ].each do |input, borders|
      expect(render_qea_route(**input, object_styles: borders)).to eq(
        paths: ["M 227 602 L 227 505", "M 232 520 L 227 505 L 222 520"], markers: []
      )
    end
  end

  it "preserves connector types outside the bordered outline contract" do
    expect(render_qea_route(**thin.merge(connector_type: "Realization"), object_styles: ["LWth=2;", "LWth=2;"]))
      .to eq(paths: ["M 227 602 L 227 505"], markers: ["227 505 233 521 221 521"])
  end
end
